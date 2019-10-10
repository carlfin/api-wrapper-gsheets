describe RowCrudGsheet::Client, 'Integration' do
  context 'read operations on sheet' do
    let!(:client) { described_class.new(ENV.fetch('TEST_DOCUMENT'), 'rspecmock_read') }

    it 'can read rows un-indexed with explicit no headers' do
      expect(client.get_spreadsheet_values(header_rows: 0).size).to be(4)
    end

    it 'can read rows indexed' do
      expect(client.get_spreadsheet_values_indexed('ID').size).to be(3)
    end

    it 'can build row index correct' do
      expect(client.get_spreadsheet_values_indexed('ID').keys).to match_array(%w[1 2 3])
    end

    it 'can read correct amount of fields' do
      expect(client.get_spreadsheet_values_indexed['1'].size).to be(2)
    end
  end

  context 'write/delete/append operations on sheet' do
    let!(:client) { described_class.new(ENV.fetch('TEST_DOCUMENT'), 'rspecmock_rw') }

    def random_row
      [rand(1000), rand(1000), rand(1000)].map(&:to_s)
    end

    it 'can delete two rows' do
      before_size = client.get_spreadsheet_values.size
      delete_rows = (2..before_size).to_a.sample(2)
      client.delete_rows(delete_rows)
      expect(client.get_spreadsheet_values.size).to be(before_size - 2)
    end

    it 'can add two rows' do
      before_size = client.get_spreadsheet_values.size
      client.append_spreadsheet_values(
        {
          values: Array.new(2).map { random_row }
        }
      )
      expect(client.get_spreadsheet_values.size).to be(before_size + 2)
    end

    it 'can update a single row' do
      index = (2..client.get_spreadsheet_values_indexed.size).to_a.sample
      upval = random_row
      client.update_spreadsheet_values("A#{index}:C#{index}", values: [upval])

      expect(client.get_spreadsheet_values_indexed[upval[0].to_s]).to match_array(upval[1..2])
    end
  end
end
