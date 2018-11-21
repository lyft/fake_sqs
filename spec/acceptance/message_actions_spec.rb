require "spec_helper"

describe "Actions for Messages", :sqs do

  before do
    sqs.create_queue(queue_name: "test")
  end

  let(:sqs) { Aws::SQS::Client.new }
  let(:resource) { Aws::SQS::Resource.new }
  let(:queue) { resource.get_queue_by_name(queue_name: "test") }

  specify "SendMessage" do
    msg = "this is my message"
    result = queue.send_message(message_body: msg)
    result.md5_of_message_body.should eq Digest::MD5.hexdigest(msg)
  end

  specify "ReceiveMessage" do
    body = "test 123"
    queue.send_message(message_body: body)
    messages = queue.receive_messages
    messages.first.body.should eq body
  end

  specify "DeleteMessage" do
    queue.send_message(message_body: "test")

    messages = queue.receive_messages
    messages.first.delete

    let_messages_in_flight_expire
    expect(queue.receive_messages.size).to eq 0
  end

  specify "DeleteMessageBatch" do
    queue.send_message(message_body: "test1")
    queue.send_message(message_body: "test2")

    queue.receive_messages(max_number_of_messages: 10).batch_delete!

    let_messages_in_flight_expire
    expect(queue.receive_messages.size).to eq 0
  end

  specify "SendMessageBatch" do
    bodies = %w(a b c)
    entries = bodies.map { |msg| { id: msg, message_body: msg } }
    queue.send_messages(entries: entries)

    messages = queue.receive_messages(max_number_of_messages: 10)
    messages.map(&:body).should match_array bodies
  end

  specify "set message timeout to 0" do
    body = 'some-sample-message'
    queue.send_message(message_body: body)
    messages = queue.receive_messages
    messages.first.body.should == body
    messages.first.change_visibility(visibility_timeout: 0)

    same_messages = queue.receive_messages
    same_messages.first.body.should == body
  end

  specify 'set message timeout and wait for message to come' do
    body = 'some-sample-message'
    queue.send_message(message_body: body)

    messages = queue.receive_messages
    messages.first.body.should == body
    messages.first.change_visibility(visibility_timeout: 3)

    nothing = queue.receive_messages
    nothing.size.should eq 0

    sleep(10)

    same_messages = queue.receive_messages
    same_messages.size.should eq 1
    same_messages.first.body.should == body
  end

  specify 'should fail if trying to update the visibility_timeout for a message that is not in flight' do
    body = 'some-sample-message'
    queue.send_message(message_body: body)
    messages = queue.receive_messages
    messages.first.body.should == body
    messages.first.change_visibility(visibility_timeout: 0)

    expect do
      messages.first.change_visibility(visibility_timeout: 30)
    end.to raise_error(Aws::SQS::Errors::MessageNotInflight)
  end

  def let_messages_in_flight_expire
    $fake_sqs.expire
  end

end
