require 'cgi'
require 'logger'
require 'open-uri'
require 'rubygems'
require 'json'
require 'yaml'
require 'zlib'

class Yelp
  # Provides access to the Yelp search facilities as documented at:
  #
  # http://www.yelp.com/developers/documentation
  #
  # Example usage:
  #
  #    client = Yelp::Client.new
  #    request = Yelp::Review::Request::Location.new(
  #                 :address => '650 Mission St',
  #                 :city => 'San Francisco',
  #                 :state => 'CA',
  #                 :radius => 2,
  #                 :term => 'cream puffs',
  #                 :yws_id => 'YOUR_YWSID_HERE')
  #    response = client.search(request)
  #
  # By default, response content is formatted as a Ruby hash converted from
  # Yelp's source JSON response content.  Alternate response formats can be
  # specified on request record construction via the Yelp::Request
  # +response_format+ parameter, available in all request record types.
  #
  class Client
    # allows specifying the user agent string to submit with search requests
    attr_accessor :agent
    
    # whether debug mode is enabled for logging purposes, defaulting to false
    attr_accessor :debug
    
    # the Logger compatible object with which log messages are outputted,
    # defaulting to output to STDOUT
    attr_accessor :logger

    # the default user agent submitted with search requests
    DEFAULT_AGENT = 'yelp for Ruby (http://www.rubyforge.org/projects/yelp/)'

    # Constructs a new client that uses the supplied YWSID for submitting
    # search requests.
    #
    def initialize
      @agent = DEFAULT_AGENT
      @debug = false
      @logger = nil
    end
    
    # Submits the supplied search request to Yelp and returns the response in
    # the format specified by the request.
    #
    def search (request)
      # build the full set of hash params with which the url is constructed
      params = request.to_yelp_params

      # construct the url with which we obtain results
      url = build_url(request.base_url, params)
      debug_msg "submitting search [url=#{url}, request=#{request.to_yaml}]."

      # submit the http request for the results
      http_params = { 'User-Agent' => @agent }
      http_params['Accept-Encoding'] = 'gzip,deflate' if request.compress_response?
      source = open(url, http_params)

      # read the response content
      content = (request.compress_response?) ? Zlib::GzipReader.new(source).read : source.read
      debug_msg((request.response_format.serialized?) ? "received response [content_length=#{content.length}]." : "received response [content_length=#{content.length}, content=#{content}].")

      # format the output as specified in the request
      format_content(request.response_format, content)
    end

    def raw_search_url(request)
      build_url(request.base_url,request.to_yelp_params)
    end

    protected

      def format_content (response_format, content)
        (response_format == Yelp::ResponseFormat::JSON_TO_RUBY) ? JSON.parse(content) : content
      end

      def debug_msg (message)
        return if !@debug
        @logger = Logger.new(STDOUT) if (!@logger)
        @logger.debug message
      end

      def build_url (base_url, params)
        url = base_url.clone
        url << '?'
        param_count = 0
        params.each do |key, value|
          next if value.nil?
          url << '&' if (param_count > 0)

          #Yelp allows requests to filter on multiple categories 
          #these are delimited by the plus '+' symbol in the request url
          #CGI.escape will replace the '+' character so a check
          #must be made here.
          if (key == :category && params[:category].is_a?(Array))
            url << "#{key}=#{params[key].join('+')}"
          else
            url << "#{key}=#{CGI.escape(params[key].to_s)}"
          end
          param_count += 1
        end
        url
      end
  end
end
