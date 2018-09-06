require_relative "../lib/dock-ops-core"
require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
)

describe DockOpsCore do
  before do
    @core = DockOpsCore.new
    @core.instance_variable_set :@mode, 'test'
    config = {
      :test => ['my.yaml']
    }
    @core.instance_variable_set :@cnfg, config
  end

  describe 'as_args' do
    it 'handles string input' do
      @core.send(:as_args, 'my-arg').must_equal 'my-arg'
    end

    it 'handles single array input' do
      @core.send(:as_args, ['my-arg']).must_equal 'my-arg'
    end

    it 'handles multi array input' do
      @core.send(:as_args, ['my-arg', 'other']).must_equal 'my-arg other'
    end

    it 'excludes empty array elements' do
      @core.send(:as_args, ['my-arg', nil, 'other']).must_equal 'my-arg other'
    end
  end

  describe 'compose' do
    it 'returns docker-compose command for single yaml' do
      @core.send(:compose).must_equal 'docker-compose -f my.yaml'
    end

    it 'returns docker-compose command for multiple yamls' do
      config = {
        :test => ['first', 'second']
      }
      @core.instance_variable_set :@cnfg, config
      @core.send(:compose).must_equal 'docker-compose -f first -f second'
    end

    it 'returns docker-compose command for no yamls' do
      config = {}
      @core.instance_variable_set :@cnfg, config
      @core.send(:compose).must_equal 'docker-compose '
    end
  end

end
