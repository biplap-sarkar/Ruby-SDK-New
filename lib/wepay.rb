##
# Copyright (c) 2015 WePay.
#
# http://opensource.org/licenses/Apache2.0
##

require 'cgi'
require 'json'
require 'net/http'
require 'net/https'
require 'rubygems'
require 'uri'

##
# The root WePay namespace.
##
module WePay

  ##
  # A very simple wrapper for the WePay API.
  ##
  class Client

    STAGE_API_ENDPOINT = "http://10.0.2.2/v2"
    STAGE_UI_ENDPOINT = "http://10.0.0.2/v2"
  
    PRODUCTION_API_ENDPOINT = "http://10.0.2.2/v2"
    PRODUCTION_UI_ENDPOINT = "http://10.0.2.2/v2"

    attr_reader :api_endpoint
    attr_reader :api_version
    attr_reader :client_id
    attr_reader :client_secret
    attr_reader :ui_endpoint

    ##
    # Initializes the API application.
    ##
    def initialize(client_id, client_secret, use_stage = true, api_version = nil)
      @client_id = client_id.to_s
      @client_secret = client_secret.to_s
      @api_version = api_version.to_s

      if use_stage
        @api_endpoint = STAGE_API_ENDPOINT
        @ui_endpoint = STAGE_UI_ENDPOINT
      else
        @api_endpoint = PRODUCTION_API_ENDPOINT
        @ui_endpoint = PRODUCTION_UI_ENDPOINT
      end
    end

    ##
    # Execute a call to the WePay API.
    ##
    def call(call, access_token = false, params = {})
      url = URI.parse(@api_endpoint + (call[0,1] == '/' ? call : "/#{ call }"))
      call = Net::HTTP::Post.new(url.path, initheader = {
        'Content-Type' => 'application/json',
        'User-Agent'   => 'WePay Ruby SDK'
      })

      unless params.empty?{}
        params = params.merge({
          "client_id"     => @client_id,
          "client_secret" => @client_secret
        })
      end

      if access_token then call.add_field('Authorization', "Bearer #{access_token}"); end
      if @api_version then call.add_field('Api-Version', @api_version); end

      make_request(call, url)
    end

    ##
    # Returns the OAuth 2.0 URL that users should be redirected to for
    # authorizing your API application. The `redirect_uri` must be a
    # fully-qualified URL (e.g., `https://www.wepay.com`).
    ##
    def oauth2_authorize_url(
      redirect_uri,
      user_email = false,
      user_name = false,
      permissions = "manage_accounts,collect_payments,view_user,send_money,preapprove_payments,manage_subscriptions"
    )
      url = @ui_endpoint
          + '/oauth2/authorize?client_id=' + @client_id.to_s
          + '&redirect_uri=' + redirect_uri
          + '&scope=' + permissions

      url += user_name ? '&user_name=' + CGI::escape(user_name) : ''
      url += user_email ? '&user_email=' + CGI::escape(user_email) : ''
    end

    ##
    # Call the `/v2/oauth2/token` endpoint to exchange an OAuth 2.0 `code` for an `access_token`.
    ##
    def oauth2_token(code, redirect_uri)
      call('/oauth2/token', false, {
        'client_id'     => @client_id,
        'client_secret' => @client_secret,
        'redirect_uri'  => redirect_uri,
        'code'          => code
      })
    end

private

    ##
    # Make the HTTP request to the endpoint.
    ##
    def make_request(call, url)
      request = Net::HTTP.new(url.host, url.port)
      request.read_timeout = 30
      request.use_ssl = false
      response = request.start {|http| http.request(call) }
      JSON.parse(response.body)
    end
  end
end
