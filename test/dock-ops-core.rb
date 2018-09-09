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

  describe 'parse_args' do
    it 'throws on empty input' do
      assert_raises BadArgsError do
        @core.send(:parse_args)
      end
    end

    it 'handles simple command' do
      @core.send(:parse_args, ['up']).must_equal ['up']
    end

    it 'handles command with args' do
      @core.send(:parse_args, ['up', '-d']).must_equal ['up', '-d']
    end

    it 'defaults to development mode with no flags' do
      @core.send(:parse_args, ['up', '-d']).must_equal ['up', '-d']
      assert_equal @core.instance_variable_get(:@mode), :development
    end

    it 'sets mode with -p flag' do
      @core.send(:parse_args, ['-p', 'up', '-d']).must_equal ['up', '-d']
      assert_equal @core.instance_variable_get(:@mode), :production
    end

    it 'sets arbitrary mode with -m flag' do
      @core.send(:parse_args, ['-m', 'mine', 'up', '-d']).must_equal ['up', '-d']
      assert_equal @core.instance_variable_get(:@mode), :mine
    end

    it 'sets production mode with -m flag' do
      @core.send(:parse_args, ['-m', 'production', 'up', '-d']).must_equal ['up', '-d']
      assert_equal @core.instance_variable_get(:@mode), :production
    end

    it 'delegates to compose with -nc flag' do
      @core.send(:parse_args, ['-nc', 'passthru']).must_equal [:compose, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :development
    end

    it 'delegates to docker with -nd flag' do
      @core.send(:parse_args, ['-nd', 'passthru']).must_equal [:docker, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :development
    end

    it 'delegates to machine with -nm flag' do
      @core.send(:parse_args, ['-nm', 'passthru']).must_equal [:machine, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :development
    end

    it 'delegates and sets mode' do
      @core.send(:parse_args, ['-p', '-nm', 'passthru']).must_equal [:machine, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :production
    end

    it 'delegates and sets mode in other order' do
      @core.send(:parse_args, ['-nm', '-p', 'passthru']).must_equal [:machine, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :production
    end

    it 'delegates and sets arbitrary mode' do
      @core.send(:parse_args, ['-nm', '-m', 'mine', 'passthru']).must_equal [:machine, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :mine
    end
  end

end
