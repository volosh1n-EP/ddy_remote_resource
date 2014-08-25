require 'spec_helper'

describe RemoteResource::Request do

  module RemoteResource
    class RequestDummy
      include RemoteResource::Base

      self.site = 'http://www.foobar.com'

      attr_accessor :name

    end
  end

  let(:dummy_class) { RemoteResource::RequestDummy }
  let(:dummy)       { dummy_class.new id: '12' }

  let(:resource)           { dummy_class }
  let(:rest_action)        { :get }
  let(:connection_options) { {} }
  let(:attributes) do
    { name: 'Mies' }
  end

  let(:request) { described_class.new resource, rest_action, attributes, connection_options.dup }

  describe '#connection' do
    it 'uses the connection of the resource_klass' do
      expect(request.connection).to eql Typhoeus::Request
    end
  end

  describe '#connection_options' do
    let(:threaded_connection_options_thread_name) { 'remote_resource.request_dummy.threaded_connection_options' }

    before { Thread.current[threaded_connection_options_thread_name] = threaded_connection_options }
    after  { Thread.current[threaded_connection_options_thread_name] = nil }

    context 'when the given connection_options contain other values than the resource threaded_connection_options or connection_options' do
      let(:connection_options) do
        {
          site: 'http://www.barbaz.com',
          collection: true,
          path_prefix: '/api',
          root_element: :bazbar
        }
      end

      let(:threaded_connection_options) do
        {
          site: 'http://www.bazbazbaz.com',
          path_prefix: '/registration',
          path_postfix: '/promotion',
          root_element: :bazbazbaz
        }
      end

      it 'merges the given connection_options with the resource connection_options while taking precedence over the resource connection_options after the threaded_connection_options' do
        expect(request.connection_options[:site]).to eql 'http://www.barbaz.com'
        expect(request.connection_options[:collection]).to eql true
        expect(request.connection_options[:path_prefix]).to eql '/api'
        expect(request.connection_options[:path_postfix]).to eql '/promotion'
        expect(request.connection_options[:root_element]).to eql :bazbar
      end
    end

    context 'when the given connection_options do NOT contain other values than the resource threaded_connection_options or connection_options' do
      let(:connection_options) do
        {
          collection: true,
          path_prefix: '/api',
          root_element: :bazbar
        }
      end

      let(:threaded_connection_options) do
        {
          site: 'http://www.bazbazbaz.com',
          path_prefix: '/api',
          path_postfix: '/promotion'
        }
      end

      it 'merges the given connection_options with the resource threaded_connection_options and connection_options' do
        expect(request.connection_options[:site]).to eql 'http://www.bazbazbaz.com'
        expect(request.connection_options[:collection]).to eql true
        expect(request.connection_options[:path_prefix]).to eql '/api'
        expect(request.connection_options[:path_postfix]).to eql '/promotion'
        expect(request.connection_options[:root_element]).to eql :bazbar
      end
    end
  end

  describe '#original_connection_options' do
    let(:threaded_connection_options_thread_name) { 'remote_resource.request_dummy.threaded_connection_options' }

    before { Thread.current[threaded_connection_options_thread_name] = threaded_connection_options }
    after  { Thread.current[threaded_connection_options_thread_name] = nil }

    context 'when the given connection_options (original_connection_options) contain other values than the resource threaded_connection_options' do
      let(:connection_options) do
        {
          site: 'http://www.barbaz.com',
          collection: true,
          path_prefix: '/api',
          root_element: :bazbar
        }
      end

      let(:threaded_connection_options) do
        {
          site: 'http://www.bazbazbaz.com',
          path_prefix: '/registration',
          path_postfix: '/promotion',
          root_element: :bazbazbaz
        }
      end

      it 'merges the given connection_options (original_connection_options) with the resource threaded_connection_options while taking precedence over the resource threaded_connection_options' do
        expect(request.original_connection_options[:site]).to eql 'http://www.barbaz.com'
        expect(request.original_connection_options[:collection]).to eql true
        expect(request.original_connection_options[:path_prefix]).to eql '/api'
        expect(request.original_connection_options[:path_postfix]).to eql '/promotion'
        expect(request.original_connection_options[:root_element]).to eql :bazbar
      end
    end

    context 'when the given connection_options (original_connection_options) do NOT contain other values than the resource threaded_connection_options' do
      let(:connection_options) do
        {
          collection: true,
          path_prefix: '/api',
          root_element: :bazbar
        }
      end

      let(:threaded_connection_options) do
        {
          site: 'http://www.bazbazbaz.com',
          path_prefix: '/api',
          path_postfix: '/promotion'
        }
      end

      it 'merges the given connection_options (original_connection_options) with the resource threaded_connection_options' do
        expect(request.original_connection_options[:site]).to eql 'http://www.bazbazbaz.com'
        expect(request.original_connection_options[:collection]).to eql true
        expect(request.original_connection_options[:path_prefix]).to eql '/api'
        expect(request.original_connection_options[:path_postfix]).to eql '/promotion'
        expect(request.original_connection_options[:root_element]).to eql :bazbar
      end
    end
  end

  describe '#perform' do
    let(:connection)             { Typhoeus::Request }
    let(:determined_request_url) { 'http://www.foobar.com/request_dummy.json' }
    let(:determined_attributes)  { attributes }
    let(:determined_headers)     { { "Accept"=>"application/json" } }

    let(:typhoeus_request)  { Typhoeus::Request.new determined_request_url }
    let(:typhoeus_response) do
      response = Typhoeus::Response.new
      response.request = typhoeus_request
      response
    end

    let(:determined_connection_options) { request.connection_options }

    before { allow_any_instance_of(Typhoeus::Request).to receive(:run) { typhoeus_response } }

    context 'when the rest_action is :get' do
      let(:rest_action) { 'get' }

      it 'makes a GET request with the attributes as params' do
        expect(connection).to receive(:get).with(determined_request_url, params: determined_attributes, headers: determined_headers).and_call_original
        request.perform
      end

      it 'makes a RemoteResource::Response object with the Typhoeus::Response object and the connection_options' do
        expect(RemoteResource::Response).to receive(:new).with(typhoeus_response, determined_connection_options).and_call_original
        request.perform
      end

      it 'returns a RemoteResource::Response object' do
        expect(request.perform).to be_a RemoteResource::Response
      end
    end

    context 'when the rest_action is :put' do
      let(:rest_action) { 'put' }

      it 'makes a PUT request with the attributes as body' do
        expect(connection).to receive(:put).with(determined_request_url, body: determined_attributes, headers: determined_headers).and_call_original
        request.perform
      end

      it 'makes a RemoteResource::Response object with the Typhoeus::Response object and the connection_options' do
        expect(RemoteResource::Response).to receive(:new).with(typhoeus_response, determined_connection_options).and_call_original
        request.perform
      end

      it 'returns a RemoteResource::Response object' do
        expect(request.perform).to be_a RemoteResource::Response
      end
    end

    context 'when the rest_action is :put' do
      let(:rest_action) { 'put' }

      it 'makes a PUT request with the attributes as body' do
        expect(connection).to receive(:put).with(determined_request_url, body: determined_attributes, headers: determined_headers).and_call_original
        request.perform
      end

      it 'makes a RemoteResource::Response object with the Typhoeus::Response object and the connection_options' do
        expect(RemoteResource::Response).to receive(:new).with(typhoeus_response, determined_connection_options).and_call_original
        request.perform
      end

      it 'returns a RemoteResource::Response object' do
        expect(request.perform).to be_a RemoteResource::Response
      end
    end

    context 'when the rest_action is :patch' do
      let(:rest_action) { 'patch' }

      it 'makes a PATCH request with the attributes as body' do
        expect(connection).to receive(:patch).with(determined_request_url, body: determined_attributes, headers: determined_headers).and_call_original
        request.perform
      end

      it 'makes a RemoteResource::Response object with the Typhoeus::Response object and the connection_options' do
        expect(RemoteResource::Response).to receive(:new).with(typhoeus_response, determined_connection_options).and_call_original
        request.perform
      end

      it 'returns a RemoteResource::Response object' do
        expect(request.perform).to be_a RemoteResource::Response
      end
    end

    context 'when the rest_action is :post' do
      let(:rest_action) { 'post' }

      it 'makes a POST request with the attributes as body' do
        expect(connection).to receive(:post).with(determined_request_url, body: determined_attributes, headers: determined_headers).and_call_original
        request.perform
      end

      it 'makes a RemoteResource::Response object with the Typhoeus::Response object and the connection_options' do
        expect(RemoteResource::Response).to receive(:new).with(typhoeus_response, determined_connection_options).and_call_original
        request.perform
      end

      it 'returns a RemoteResource::Response object' do
        expect(request.perform).to be_a RemoteResource::Response
      end
    end

    context 'when the rest_action is unknown' do
      let(:rest_action) { 'foo' }

      it 'raises the RemoteResource::Request::RESTActionUnknown error' do
        expect{ request.perform }.to raise_error RemoteResource::Request::RESTActionUnknown, "for action: 'foo'"
      end
    end
  end

  describe '#determined_request_url' do
    context 'the attributes contain an id' do
      let(:attributes) do
        { id: 12, name: 'Mies' }
      end

      it 'uses the id for the request url' do
        expect(request.determined_request_url).to eql 'http://www.foobar.com/request_dummy/12.json'
      end
    end

    context 'the attributes do NOT contain an id' do
      it 'does NOT use the id for the request url' do
        expect(request.determined_request_url).to eql 'http://www.foobar.com/request_dummy.json'
      end
    end

    context 'the given connection_options (original_connection_options) contain a base_url' do
      let(:connection_options) do
        { base_url: 'http://www.foo.com/api' }
      end

      it 'uses the base_url for the request url' do
        expect(request.determined_request_url).to eql 'http://www.foo.com/api.json'
      end
    end

    context 'the given connection_options (original_connection_options) do NOT contain a base_url' do
      it 'does NOT use the base_url for the request url' do
        expect(request.determined_request_url).to eql 'http://www.foobar.com/request_dummy.json'
      end
    end

    context 'the given connection_options contain a collection' do
      let(:connection_options) do
        { collection: true }
      end

      it 'uses the collection to determine the base_url for the request url' do
        expect(request.determined_request_url).to eql 'http://www.foobar.com/request_dummies.json'
      end
    end

    context 'the connection_options contain a content_type' do
      let(:connection_options) do
        { content_type: '' }
      end

      it 'uses the content_type for the request url' do
        expect(request.determined_request_url).to eql 'http://www.foobar.com/request_dummy'
      end
    end

    context 'the connection_options do NOT contain a content_type' do
      it 'does NOT use the content_type for the request url' do
        expect(request.determined_request_url).to eql 'http://www.foobar.com/request_dummy.json'
      end
    end
  end

  describe '#determined_attributes' do
    context 'the connection_options contain no_params' do
      let(:connection_options) do
        { no_params: true }
      end

      it 'returns an empty Hash' do
        expect(request.determined_attributes).to eql({})
      end
    end

    context 'the connection_options do NOT contain a no_params' do
      it 'does NOT return an empty Hash' do
        expect(request.determined_attributes).not_to eql({})
      end
    end

    context 'the connection_options contain a root_element' do
      let(:connection_options) do
        { root_element: :foobar }
      end

      let(:packed_up_attributes) do
        { 'foobar' => { name: 'Mies' } }
      end

      it 'packs up the attributes with the root_element' do
        expect(request.determined_attributes).to eql packed_up_attributes
      end
    end

    context 'the connection_options do NOT contain a root_element' do
      it 'does NOT pack up the attributes with the root_element' do
        expect(request.determined_attributes).to eql attributes
      end
    end
  end

  describe '#determined_headers' do
    let(:headers) do
      { 'Baz' => 'FooBar' }
    end

    context 'the connection_options contain a default_headers' do
      let(:default_headers) do
        { 'Foo' => 'Bar' }
      end

      context 'and the given connection_options (original_connection_options) contain a headers' do
        let(:connection_options) do
          { default_headers: default_headers, headers: headers }
        end

        it 'uses the default_headers for the request headers' do
          expect(request.determined_headers).to eql({ "Foo"=>"Bar" })
        end
      end

      context 'and the given connection_options (original_connection_options) do NOT contain a headers' do
        let(:connection_options) do
          { default_headers: default_headers }
        end

        it 'uses the default_headers for the request headers' do
          expect(request.determined_headers).to eql({ "Foo"=>"Bar" })
        end
      end
    end

    context 'the connection_options do NOT contain a default_headers' do
      context 'and the given connection_options (original_connection_options) contain a headers' do
        let(:connection_options) do
          { headers: headers }
        end

        it 'uses the headers for the request headers' do
          expect(request.determined_headers).to eql({ "Accept"=>"application/json", "Baz"=>"FooBar" })
        end
      end

      context 'and the given connection_options (original_connection_options) do NOT contain a headers' do
        context 'and the resource contains a extra_headers' do
          it 'uses the headers of the resource for the request headers' do
            dummy_class.extra_headers = { "BarBaz" => "Baz" }
            dummy_class.connection_options.reload!

            expect(request.determined_headers).to eql({ "Accept"=>"application/json",  "BarBaz"=>"Baz" })

            dummy_class.extra_headers = nil
            dummy_class.connection_options.reload!
          end
        end

        context 'and the resource does NOT contain a extra_headers' do
          it 'does NOT use the headers for the request headers' do
            expect(request.determined_headers).to eql({ "Accept"=>"application/json" })
          end
        end
      end
    end
  end

  describe '#resource_klass' do
    context 'when the resource is a RemoteResource class' do
      let(:resource) { dummy_class }

      it 'returns the resource' do
        expect(request.send :resource_klass).to eql RemoteResource::RequestDummy
      end
    end

    context 'when the resource is a RemoteResource object' do
      let(:resource) { dummy }

      it 'returns the Class of the resource' do
        expect(request.send :resource_klass).to eql RemoteResource::RequestDummy
      end
    end
  end

end