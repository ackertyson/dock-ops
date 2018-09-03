require_relative "../lib/dock-ops"
require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
)

describe DockOps do
  before do
    @dock = DockOps.new
    @dock.instance_variable_set :@mode, 'test'
  end

  describe 'as_args' do
    it 'handles string input' do
      @dock.send(:as_args, 'my-arg').must_equal 'my-arg'
    end

    it 'handles single array input' do
      @dock.send(:as_args, ['my-arg']).must_equal 'my-arg'
    end

    it 'handles multi array input' do
      @dock.send(:as_args, ['my-arg', 'other']).must_equal 'my-arg other'
    end

    it 'excludes empty array elements' do
      @dock.send(:as_args, ['my-arg', nil, 'other']).must_equal 'my-arg other'
    end
  end

  describe 'compose' do
    before do
      config = {
        :test => ['my-yaml']
      }
      @dock.instance_variable_set :@cnfg, config
    end

    it 'returns docker-compose command for single yaml' do
      @dock.send(:compose).must_equal 'docker-compose -f my-yaml'
    end

    it 'returns docker-compose command for multiple yamls' do
      config = {
        :test => ['first', 'second']
      }
      @dock.instance_variable_set :@cnfg, config
      @dock.send(:compose).must_equal 'docker-compose -f first -f second'
    end

    it 'returns docker-compose command for no yamls' do
      config = {}
      @dock.instance_variable_set :@cnfg, config
      @dock.send(:compose).must_equal 'docker-compose '
    end
  end
end
