require 'google/apis/sheets_v4'

module RowCrudGsheet
class Client
  BATCH_SIZE = 512

  attr_reader :service, :sheet_key

  def initialize(sheet_key)
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(ENV.fetch('GSHEET_AUTH_JSON')),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
    @sheet_key = sheet_key
  end

  def update_spreadsheet_values(range, values)
    service.update_spreadsheet_value(sheet_key, 'data!' + range, values, value_input_option: 'USER_ENTERED')
  end

  def append_spreadsheet_values(values)
    service.append_spreadsheet_value(sheet_key, 'data', values, value_input_option: 'USER_ENTERED')
  end

  def get_spreadsheet_values
    max = service.get_spreadsheet_values(sheet_key, 'data!A:A').values.size
    index = SheetdataIndex.new
    ((max / BATCH_SIZE) + 1).times.each_with_object([]) do |i, indexed|
      index.append_data(
        service.get_spreadsheet_values(
          sheet_key,
          "data!#{i * BATCH_SIZE + 1}:#{(i + 1) * BATCH_SIZE + 1}"
        ).values
      )
    end
    index
  end

  def get_spreadsheet_values_indexed(index_key = 'Deal ID')
    values = get_spreadsheet_values
    headers = values.shift
    index_column = headers.index(index_key)
    index = SheetdataIndex.new(index_column)
    values.raw_data.each do |raw|
      processed = Marshal.load(LZ4::uncompress(raw))
      index.append_data(processed)
    end
    index
  end

  def column_name_on_index(index)
    name = 'A'
    index.times { name.succ! }
    name
  end

  def sheet_id
    @sheet_id ||= service.get_spreadsheet(sheet_key).sheets.map(&:properties).map(&:to_h).find { |s| s[:title] == 'data' }[:sheet_id]
  end

  def delete_rows(indices)
    request_body = {
      requests: indices.map do |index|
        {
          delete_dimension: {
            range: {
              dimension: 'ROWS',
              sheet_id: sheet_id,
              start_index: index,
              end_index: index + 1
            }
          }
        }
      end
    }
    service.batch_update_spreadsheet(sheet_key, request_body, {})
    indices
  end

  def delete_row(index)
    request_body = {
      requests: [
        {
          delete_dimension: {
            range: {
              dimension: 'ROWS',
              sheet_id: sheet_id,
              start_index: index,
              end_index: index + 1
            }
          }
        }
      ]
    }
    service.batch_update_spreadsheet(sheet_key, request_body, {})
    index
  end
end
end
