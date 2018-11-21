require "spec_helper"

describe "Actions for Queues", :sqs do

  let(:sqs) { Aws::SQS::Client.new }
  let(:resource) { Aws::SQS::Resource.new }

  def create_queue(name)
    resource.queue(sqs.create_queue(queue_name: name).queue_url)
  end

  specify "CreateQueue" do
    queue = create_queue "test-create-queue"

    queue.url.should eq "http://0.0.0.0:4568/test-create-queue"
    queue.attributes['QueueArn'].should match %r"arn:aws:sqs:us-east-1:.+:test-create-queue"
  end

  specify "GetQueueUrl" do
    create_queue "test-get-queue-url"

    queue = resource.get_queue_by_name(queue_name: "test-get-queue-url")
    queue.url.should eq "http://0.0.0.0:4568/test-get-queue-url"
  end

  specify "ListQueues" do
    create_queue "test-list-1"
    create_queue "test-list-2"

    sqs.list_queues.queue_urls.should eq [
      "http://0.0.0.0:4568/test-list-1",
      "http://0.0.0.0:4568/test-list-2"
    ]
  end

  specify "ListQueues with prefix" do
    create_queue "test-list-1"
    create_queue "test-list-2"
    create_queue "other-list-3"

    sqs.list_queues(queue_name_prefix: "test").queue_urls.should eq [
      "http://0.0.0.0:4568/test-list-1",
      "http://0.0.0.0:4568/test-list-2",
    ]
  end

  specify "DeleteQueue" do
    url = create_queue("test-delete").url
    expect(sqs.list_queues.queue_urls.size).to eq 1

    resource.queue(url).delete
    expect(sqs.list_queues.queue_urls.size).to eq 0
  end

  specify "SetQueueAttributes / GetQueueAttributes" do
    queue = create_queue "my-queue"
    policy = {
      Version: "2008-10-17",
      Id: "#{queue.attributes['QueueArn']}/SQSDefaultPolicy",
      Statement: [
        {
          Effect: "Allow",
          Principal: {
            AWS: "*"
          },
          Action: ["SQS:SendMessage"],
          Resource: "#{queue.attributes['QueueArn']}"
        }
      ]
    }

    sqs.set_queue_attributes(
      queue_url: queue.url,
      attributes: {
        Policy: policy.to_json
      }
    )

    reloaded_policy = resource.get_queue_by_name(queue_name: "my-queue").attributes['Policy']
    JSON.parse(reloaded_policy, symbolize_names: true).should eq policy
  end

end
