require 'helper'

describe MessageBird::HTTP::Sender do

  let(:uri){ OpenStruct.new(:host => :foo, :port => :bar) }
  let(:mock_connection){ OpenStruct.new(:use_ssl => nil) }
  let(:sms){ OpenStruct.new(:uri => uri)}
  let(:response_factory){ lambda{|foo|'FooBar'} }


  subject{ MessageBird::HTTP::Sender }

  before do
    subject.response_factory = response_factory
    stub(mock_connection).request{:bar}
  end

  after do
    subject.enabled = false
  end

  describe '#connection_class' do
    it 'returns a Net::HTTP class' do
      subject.enabled = true
      subject.send(:connection_class).must_equal Net::HTTP
    end

    describe 'local_loop variable set to true' do
      it 'returns a LocalConnection class' do
        subject.send(:connection_class).must_equal MessageBird::HTTP::LocalConnection
      end
    end
  end

  describe '#create_connection' do
    it 'creates a new connection' do
      mock(MessageBird::HTTP::LocalConnection).new.with_any_args{mock_connection}
      subject.send :create_connection, uri
    end

    it 'sets the connection to SSL' do
      mock(mock_connection).use_ssl=(true)
      stub(MessageBird::HTTP::LocalConnection).new.with_any_args{mock_connection}
      subject.send :create_connection, uri
    end
  end

  describe '#create_request' do
    it 'works' do
      mock(Net::HTTP::Get).new(:bar).once
      subject.send :create_request, :bar
    end
  end

  describe '#deliver' do
    it 'sends the given sms' do
      stub(subject).ensure_valid_sms!
      mock(subject).send_sms(:foo)
      subject.deliver(:foo)
    end

    it 'takes an optional block' do
      stub(subject).ensure_valid_sms!
      stub(subject).create_connection.with_any_args
      stub(subject).create_request.with_any_args
      stub(subject).send_request.with_any_args{'FooBat'}
      subject.send(:send_sms, sms) do |response|
        response.must_equal 'FooBat'
      end
    end

    it 'raises an ArgumentError when given object is not a valid SMS' do
      assert_raises(ArgumentError){
        subject.deliver('string')
      }
    end
  end

  describe '#response_factory' do
    it 'works' do
      subject.send(:response_factory).is_a?(Method)
    end
  end

  describe '#send_request' do
    it 'calls the response_factory' do
      mock(subject.send(:response_factory)).call(:bar).once
      subject.send :send_request, mock_connection, 'bar'
    end
  end

  describe '#send_sms' do
    it 'creates a connection' do
      mock(subject).create_connection.with_any_args
      stub(subject).create_request.with_any_args{:foo}
      stub(subject).send_request.with_any_args{:bar}
      subject.send :send_sms, sms
    end

    it 'creates a request' do
      stub(subject).create_connection.with_any_args
      mock(subject).create_request.with_any_args{:foo}
      stub(subject).send_request.with_any_args{:bar}
      subject.send :send_sms, sms
    end

    it 'sends the request over the connection' do
      stub(subject).create_connection.with_any_args{:foo}
      stub(subject).create_request.with_any_args{:bar}
      mock(subject).send_request(:foo, :bar){:bat}
      subject.send :send_sms, sms
    end
  end

end
