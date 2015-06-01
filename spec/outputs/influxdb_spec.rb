require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/influxdb"

describe LogStash::Outputs::InfluxDB do

  let(:pipeline) { LogStash::Pipeline.new(config) }

  context "complete pipeline run with 2 events" do

    let(:config) do <<-CONFIG
       input {
          generator {
            message => "foo=1 bar=2 time=3"
            count => 2
            type => "generator"
          }
        }

        filter {
          kv { }
        }

        output {
          influxdb {
            host => "localhost"
            user => "someuser"
            password => "somepwd"
            allow_time_override => true
            data_points => {"foo" => "%{foo}" "bar" => "%{bar}" "time" => "%{time}"}
          }
        }
      CONFIG
    end

    let(:json_result) { %q|{"database":"statistics","retentionPolicy":"default","points":[{"name":"logstash","time":"3","precision":"ms","fields":{"foo":"1","bar":"2"}},{"name":"logstash","time":"3","precision":"ms","fields":{"foo":"1","bar":"2"}}]}| }

    it "should receive 2 events, flush and call post with 2 items json array" do
      expect_any_instance_of(LogStash::Outputs::InfluxDB).to receive(:post).with(json_result)
      pipeline.run
    end

  end

  context "using event fields as data points" do
    let(:config) do <<-CONFIG
        input {
           generator {
             message => "foo=1 bar=2 time=3"
             count => 1
             type => "generator"
           }
         }

         filter {
           kv { }
         }

         output {
           influxdb {
             host => "localhost"
             allow_time_override => true
             use_event_fields_for_data_points => true
             exclude_fields => ["@version", "@timestamp", "sequence", "message", "type", "host"]
           }
         }
      CONFIG
    end

    let(:json_result) { %q|{"database":"statistics","retentionPolicy":"default","points":[{"name":"logstash","time":"3","precision":"ms","fields":{"foo":"1","bar":"2"}}]}| }

    it "should use the event fields as the data points, excluding @version and @timestamp by default as well as any fields configured by exclude_fields" do
      expect_any_instance_of(LogStash::Outputs::InfluxDB).to receive(:post).with(json_result)
      pipeline.run
    end
  end
end
