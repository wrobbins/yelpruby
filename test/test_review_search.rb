require 'pp'
require 'rubygems'
require 'test/unit'
require 'yelp'
require File.dirname(__FILE__) + '/yelp_helper'

class TestReviewSearch < Test::Unit::TestCase
  include YelpHelper

  def setup
    @client = Yelp::Client.new
    @yws_id = ENV['YWSID']
#    @client.debug = true
  end

  def test_bounding_box
    request = Yelp::Review::Request::BoundingBox.new(
                :bottom_right_latitude => 37.788022,
                :bottom_right_longitude => -122.399797,
                :top_left_latitude => 37.9,
                :top_left_longitude => -122.5,
#                :radius => 1,
#                :business_count => 3,
                :term => 'yelp',
                :yws_id => @yws_id)
    response = @client.search(request)
    validate_json_to_ruby_response(response)
  end

  def test_geo_point
    request = Yelp::Review::Request::GeoPoint.new(
                :latitude => 37.78022,
                :longitude => -122.399797,
                :radius => 2,
#                :business_count => 5,
                :term => 'yelp',
                :yws_id => @yws_id)
    response = @client.search(request)
    validate_json_to_ruby_response(response)
  end
  
  def test_location
    request = Yelp::Review::Request::Location.new(
                :address => '650 Mission St',
                :city => 'San Francisco',
                :state => 'CA',
                :radius => 2,
#                :business_count => 5,
                :term => 'cream puffs',
                :yws_id => @yws_id)
    response = @client.search(request)
    validate_json_to_ruby_response(response)
  end

  def test_category
    # perform a basic search of businesses near SOMA
    request = Yelp::Review::Request::GeoPoint.new(
                :latitude => 37.78022,
                :longitude => -122.399797,
                :radius => 5,
                :term => 'yelp',
                :yws_id => @yws_id)
    response = @client.search(request)

    # perform the same search focusing only on playgrounds
    narrowed_request = Yelp::Review::Request::GeoPoint.new(
                         :latitude => 37.78022,
                         :longitude => -122.399797,
                         :radius => 5,
                         :term => 'yelp',
                         :category => 'playgrounds',
                         :yws_id => @yws_id)
    narrowed_response = @client.search(narrowed_request)
    pp narrowed_response

    # make sure we got less for the second
    assert(response['businesses'].length > narrowed_response['businesses'].length)

    #perform the same search focusing only on playgrounds and ice cream
    more_narrowed_request = Yelp::Review::Request::GeoPoint.new(
                         :latitude => 37.78022,
                         :longitude => -122.399797,
                         :radius => 5,
                         :term => 'yelp',
                         :category => ['playgrounds','icecream'],
                         :yws_id => @yws_id)
    more_narrowed_response = @client.search(more_narrowed_request)
    #pp more_narrowed_response   
    for b in more_narrowed_response['businesses']
      assert( has_category?(b,'icecream') || has_category?(b,'playgrounds') )
    end

  end


  def test_json_response_format
    request = basic_request(:response_format => Yelp::ResponseFormat::JSON)
    response = @client.search(request)
    validate_json_response(response)
  end

  def test_json_to_ruby_response_format
    request = basic_request(:response_format => Yelp::ResponseFormat::JSON_TO_RUBY)
    response = @client.search(request)
    validate_json_to_ruby_response(response)
  end

  def test_pickle_response_format
    request = basic_request(:response_format => Yelp::ResponseFormat::PICKLE)
    @client.search(request)
    # TODO: validation
  end

  def test_php_response_format
    request = basic_request(:response_format => Yelp::ResponseFormat::PHP)
    response = @client.search(request)
    # TODO: validation
  end

  def test_compressed_response
    request = basic_request(:compress_response => true)
    response = @client.search(request)
    validate_json_to_ruby_response(response)
  end

  def test_uncompressed_response
    request = basic_request(:compress_response => false)
    response = @client.search(request)
    validate_json_to_ruby_response(response)
  end

  protected

    def basic_request (params = nil)
      default_params = {
        :city => 'San Francisco',
        :state => 'CA',
        :term => 'gordo',
        :yws_id => @yws_id
      }
      Yelp::Review::Request::Location.new(default_params.merge(params))
    end

  def has_category?(business,category_name)
    
    all_categories = []
    #categories is an array of hashes
    for category in business['categories']
      all_categories.push(category['category_filter'])
    end

    all_categories.include?(category_name) 
    
  end

end
