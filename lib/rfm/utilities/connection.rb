# Connection object takes over the communication functionality that was previously in Rfm::Server.
# TODO: Clean up the way :grammar is sent in to the initializing method.
#       Currently, the actual connection instance config doesn't get set with the correct grammar,
#       even if the http_fetch is using the correct grammar.

require 'faraday'
require 'connection_pool'

module Rfm
# These have been moved to rfm.rb.
# 	SaxParser.default_class = CaseInsensitiveHash
# 	SaxParser.template_prefix = File.join(File.dirname(__FILE__), './sax/')
# 	SaxParser.templates.merge!({
# 		:fmpxmllayout => 'fmpxmllayout.yml',
# 		:fmresultset => 'fmresultset.yml',
# 		:fmpxmlresult => 'fmpxmlresult.yml',
# 		:none => nil
# 	})
	
  class Connection
  	include Config  	
    extend Config

    def initialize(action, params, request_options={}, *args)
      config *args

      # Action sent to FMS
      @action = action
      # Query params sent to FMS
      @params = params
      # Additional options sent to FMS
      @request_options = request_options
      
      @defaults = {
        :template => :fmresultset,
        :grammar => 'fmresultset'
      }
    end

    def state(*args)
    	@defaults.merge(super(*args))
    end

    def connect(action=@action, params=@params, request_options = @request_options)
      grammar_option = request_options.delete(:grammar)
      post = params.merge(expand_options(request_options)).merge({action => ''})
      grammar = select_grammar(post, :grammar=>grammar_option)
      http_fetch("/fmi/xml/#{grammar}.xml", post)
    end

    def select_grammar(post, options={})
			grammar = state(options)[:grammar] || 'fmresultset'
			if grammar.to_s.downcase == 'auto'
				# TODO: Build grammar parser in new sax engine templates to handle FMPXMLRESULT.
				return "fmresultset"
				post.keys.find(){|k| %w(-find -findall -dbnames -layoutnames -scriptnames).include? k.to_s} ? "FMPXMLRESULT" : "fmresultset"
    	else
    		grammar
    	end
    end
    
    def parse(template=nil, initial_object=nil, parser=nil, options={})
    	template ||= state[:template]
    	#(template =  'fmresultset.yml') unless template
    	#(template = File.join(File.dirname(__FILE__), '../sax/', template)) if template.is_a? String
    	Rfm::SaxParser.parse(connect.body, template, initial_object, parser, state(*options)).result
    end

    private

    def http_fetch(path, post_data, limit=10)
      self.class.connect do |conn|
        response = conn.post(path, post_data)

        case response.status
        when 200..299
          response
        when 300..399
          raise response
        when 401..403
          msg = "The account name (#{account_name}) or password provided is not correct (or the account doesn't have the fmxml extended privilege)."
          raise Rfm::AuthenticationError.new(msg)
        when 404
          msg = "Could not talk to FileMaker because the Web Publishing Engine is not responding (server returned 404)."
          raise Rfm::CommunicationError.new(msg)
        else
          msg = "Unexpected response from server: #{response.status} (#{response.body}). Unable to communicate with the Web Publishing Engine."
          raise Rfm::CommunicationError.new(msg)
        end
      end
    end
  
    def expand_options(options)
      result = {}
      field_mapping = options.delete(:field_mapping) || {}
      options.each do |key,value|
        case key.to_sym
        when :max_portal_rows
        	result['-relatedsets.max'] = value
        	result['-relatedsets.filter'] = 'layout'
        when :ignore_portals
        	result['-relatedsets.max'] = 0
        	result['-relatedsets.filter'] = 'layout'
        when :max_records
          result['-max'] = value
        when :skip_records
          result['-skip'] = value
        when :sort_field
          if value.kind_of? Array
            raise Rfm::ParameterError.new(":sort_field can have at most 9 fields, but you passed an array with #{value.size} elements.") if value.size > 9
            value.each_index { |i| result["-sortfield.#{i+1}"] = field_mapping[value[i]] || value[i] }
          else
            result["-sortfield.1"] = field_mapping[value] || value
          end
        when :sort_order
          if value.kind_of? Array
            raise Rfm::ParameterError.new(":sort_order can have at most 9 fields, but you passed an array with #{value.size} elements.") if value.size > 9
            value.each_index { |i| result["-sortorder.#{i+1}"] = value[i] }
          else
            result["-sortorder.1"] = value
          end
        when :post_script
          if value.class == Array
            result['-script'] = value[0]
            result['-script.param'] = value[1]
          else
            result['-script'] = value
          end
        when :pre_find_script
          if value.class == Array
            result['-script.prefind'] = value[0]
            result['-script.prefind.param'] = value[1]
          else
            result['-script.presort'] = value
          end
        when :pre_sort_script
          if value.class == Array
            result['-script.presort'] = value[0]
            result['-script.presort.param'] = value[1]
          else
            result['-script.presort'] = value
          end
        when :response_layout
          result['-lay.response'] = value
        when :logical_operator
          result['-lop'] = value
        when :modification_id
          result['-modid'] = value
        else
          raise Rfm::ParameterError.new("Invalid option: #{key} (are you using a string instead of a symbol?)")
        end
      end
      return result
    end

    # Connections to FM are not actually persistent, so the sole purpose of the pool is to limit the
    # number of HTTP connections that can be made at once.  Deadlocking should be impossible.
    pool_size = state[:pool_size] || 1
    @connection_pool = ConnectionPool.new(size: pool_size) do
      scheme = if state[:ssl]
                 'https'
               else
                 'http'
               end

      port = if state[:port]
               ":#{state[:port]}"
             else
               ''
             end

      options = {
        url: "#{scheme}://#{state[:host]}#{port}/"
      }

      if state[:ssl].is_a? Hash
        options[:ssl] = state[:ssl]
      end

      # FIXME: proxy support

      Faraday.new(options) do |conn|
        conn.request :rfm_url_encoded
        conn.response :logger if state[:log_actions] || state[:log_responses]

        if state[:account_name] || state[:password]
          conn.basic_auth(state[:account_name] || '', state[:password] || '')
        end

        conn.adapter Faraday.default_adapter
      end
    end

    class << self
      def connect(&block)
        @connection_pool.with(&block)
      end
    end

		class URLEncodedMiddleware
			def initialize app
				@app = app
			end

			def call env
				env.request_headers['Content-Type'] ||= 'application/x-www-form-urlencoded'.freeze
				env.body = URI.encode_www_form(env.body)
				@app.call env
			end
		end

		Faraday::Request.register_middleware :rfm_url_encoded => URLEncodedMiddleware
  end # Connection


end # Rfm
