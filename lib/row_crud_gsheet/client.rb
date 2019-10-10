require 'google/apis/sheets_v4'

module RowCrudGsheet
  class Client
    BATCH_SIZE = 512

    attr_reader :service, :document_id, :sheet_name

    def initialize(document_id, sheet_name)
      @service = Google::Apis::SheetsV4::SheetsService.new
      @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(ENV.fetch('GSHEET_AUTH_JSON')),
        scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
      )
      @document_id = document_id
      @sheet_name = sheet_name
    end

    def update_spreadsheet_values(range, values)
      service.update_spreadsheet_value(document_id, "#{sheet_name}!" + range, values, value_input_option: 'USER_ENTERED')
    end

    def append_spreadsheet_values(values)
      service.append_spreadsheet_value(document_id, sheet_name, values, value_input_option: 'USER_ENTERED')
    end

    def get_spreadsheet_values(header_rows: 1)
      max = service.get_spreadsheet_values(document_id, "#{sheet_name}!A:A").values.size - header_rows
      index = SheetdataIndex.new
      offset = 0
      while offset < max do
        puts "added batch #{offset}"
        index.append_data(
          service.get_spreadsheet_values(
            document_id,
            "#{sheet_name}!#{offset + 1 + header_rows}:#{offset + BATCH_SIZE + header_rows}"
          ).values
        )
        offset += BATCH_SIZE
      end
      index
    end

    def get_spreadsheet_values_indexed(index_key = 'ID')
      values = get_spreadsheet_values(header_rows: 0)
      headers = values.shift
      index_offset = headers.index(index_key)
      index = SheetdataIndex.new(index_offset)
      values.raw_data.each do |raw|
        index.append_data([Marshal.load(LZ4::uncompress(raw))])
      end
      index
    end

    def column_name_on_index(index)
      name = 'A'
      index.times { name.succ! }
      name
    end

    def sheet_id
      @sheet_id ||= service.get_spreadsheet(document_id).sheets.map(&:properties).map(&:to_h).find { |s| s[:title] == sheet_name }[:sheet_id]
    end

    def delete_rows(indices)
      indices = indices.sort.reverse
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
      service.batch_update_spreadsheet(document_id, request_body, {})
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
      service.batch_update_spreadsheet(document_id, request_body, {})
      index
    end
  end
end
