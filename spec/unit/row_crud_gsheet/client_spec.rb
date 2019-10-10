describe RowCrudGsheet::Client, 'Unit' do
  context 'empty auth env' do
    before { ENV.delete('GSHEET_AUTH_JSON') }

    it 'can\'t initialize with no paramaters' do
      expect { described_class.new }.to raise_exception(ArgumentError)
    end
    it 'can\'t initialize with 2 parameters' do
      expect { described_class.new('a', 'b') }.to raise_exception(KeyError)
    end
  end

  context 'well formatted auth env' do
    before { ENV['GSHEET_AUTH_JSON'] = auth_env.to_json }
    after { ENV.delete('GSHEET_AUTH_JSON') }

    let!(:auth_env) do
      {
        client_email: 'me@you.com',
        private_key: OpenSSL::PKey::RSA.new(2048).to_pem
      }
    end

    it 'can initialize with 2 parameters' do
      expect(described_class.new('a', 'b')).to be_a(described_class)
    end
  end
end
