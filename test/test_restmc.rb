$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'restmc'
require 'test/unit'
require 'rack/test'

class RESTmcTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    app = RESTmc::Application
    app.set :environment, :test
    app.set :show_exceptions, false
    app
  end

  def test_empty_key_should_respond_with_not_found
    set_key '/'
    assert_equal 404, last_response.status
  end

  def test_key_with_whitespace_should_respond_with_not_found
    set_key URI.escape('/test key')
    assert_equal 404, last_response.status
  end

  def test_get_of_previously_set_key_should_return_correct_data
    k = create_and_set_key
    get(k)
    assert_equal 200, last_response.status
    assert_equal k, last_response.body
  end

  def test_get_of_nonexistent_key_should_respond_with_not_found
    assert_equal 404, get("/#{Kernel.rand}").status
  end

  def test_valid_post_should_respond_with_ok
    create_and_add_key
    assert_equal 200, last_response.status
  end

  def test_valid_post_should_store_value
    k = create_and_add_key
    get k
    assert_equal k, last_response.body
  end

  def test_post_of_previously_set_key_should_respond_with_conflict
    k = create_and_set_key
    add_key k
    assert_equal 409, last_response.status
  end

  def test_valid_put_should_respond_with_ok
    create_and_set_key
    assert_equal 200, last_response.status
  end

  def test_valid_put_should_store_value
    k = create_and_set_key
    get k
    assert_equal k, last_response.body
  end

  def test_put_of_previously_set_key_should_respond_with_ok
    k = create_and_set_key
    set_key k
    assert_equal 200, last_response.status
  end

  def test_delete_of_existing_key_should_respond_ok
    delete create_and_set_key
    assert_equal 200, last_response.status
  end

  def test_delete_of_nonexistent_key_should_respond_not_found
    assert_equal 404, delete("/#{Kernel.rand}").status
  end

  def test_put_with_an_expiry_should_expire
    header "Cache-Control", "max-age=1"
    k = create_and_set_key
    get k
    assert_equal k, last_response.body
    sleep 2
    get k
    assert_equal 404, last_response.status
  end

  def test_put_with_namespacing_should_encode_correctly
    k = "/name/spaced/key"
    encoded_key = "/name:spaced:key"
    set_key k
    get k
    assert_equal k, last_response.body
    get URI.escape(encoded_key)
    assert_equal k, last_response.body
  end

  # increment / decrement tests

  def test_incr_should_increase_value_by_one
    k = "INCR_KEY" || create_key
    set_key k, 123
    put("/%2B/#{k}")
    get k
    assert_equal 124, last_response.body.to_i
  end

  def test_incr_by_value_should_increase_by_given_value
    k = create_key
    set_key k, 123
    set_key "/%2B/#{k}", 17
    get k
    assert_equal 140, last_response.body.to_i
  end

  def test_incr_of_non_integer_should_increase_value_by_one
    k = create_key
    set_key k, 123
    set_key "/%2B/#{k}", "fail"
    get k
    assert_equal 124, last_response.body.to_i
  end

  def test_incr_of_unset_key_should_set_to_one
    k = create_key
    put("/%2B/#{k}")
    get k
    assert_equal 1, last_response.body.to_i
  end

  def test_decr_should_decrease_value_by_one
    k = create_key
    set_key k, 123
    put("/-/#{k}")
    get k
    assert_equal 122, last_response.body.to_i
  end

  def test_decr_by_value_should_decrease_by_given_value
    k = create_key
    set_key k, 123
    set_key "/-/#{k}", 17
    get k
    assert_equal 106, last_response.body.to_i
  end

  def test_decr_of_non_integer_should_decrease_value_by_one
    k = create_key
    set_key k, 123
    set_key "/-/#{k}", "fail"
    get k
    assert_equal 122, last_response.body.to_i
  end

  def test_decr_of_unset_key_should_set_to_zero
    k = create_key
    put("/-/#{k}")
    get k
    assert_equal 0, last_response.body.to_i
  end

  private

  def create_key
    Kernel.rand.to_s
  end

  def set_key(k, v = nil)
    v ||= k
    put(k, {}, 'rack.input' => io_for(v))
  end

  def add_key(k, v = nil)
    v ||= k
    post(k, {}, 'rack.input' => io_for(k))
  end

  def create_and_set_key
    k = create_key
    set_key k
    k
  end

  def create_and_add_key
    k = create_key
    add_key k
    k
  end

  def io_for(s)
    StringIO.new(s.to_s)
  end

end
