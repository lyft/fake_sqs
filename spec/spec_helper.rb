require "aws-sdk-sqs"
require "fake_sqs/test_integration"

Aws.config.update(
  endpoint: 'http://localhost:4568',
  access_key_id: 'fake access key',
  secret_access_key: 'fake secret key'
)

db = ENV["SQS_DATABASE"] || ":memory:"
puts "\n\e[34mRunning specs with database \e[33m#{db}\e[0m"
$fake_sqs = FakeSQS::TestIntegration.new(database: db)

RSpec.configure do |config|

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.before(:each, :sqs) { $fake_sqs.start }
  config.before(:each, :sqs) { $fake_sqs.reset }
  config.after(:suite) { $fake_sqs.stop }

end
