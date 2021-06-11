require_relative '../lib/dock-ops-core'
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
)

describe DockOpsCore do
  before do
    @core = DockOpsCore.new
    @core.instance_variable_set :@mode, :test
    config = {
      test: {
        'version' => 1,
        'compose_files' => ['my.yaml'],
        'aliases' => {}
      }
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
    it 'returns docker compose command for single yaml' do
      @core.send(:compose).must_equal 'docker compose -f my.yaml'
    end

    it 'returns docker compose command for multiple yamls' do
      config = {
        test: {
          'version' => 1,
          'compose_files' => %w[first second],
          'aliases' => {}
        }
      }
      @core.instance_variable_set :@cnfg, config
      @core.send(:compose).must_equal 'docker compose -f first -f second'
    end

    it 'returns docker compose command for no yamls' do
      config = {}
      @core.instance_variable_set :@cnfg, config
      @core.send(:compose).must_equal 'docker compose '
    end
  end

  describe 'default_setup' do
    it 'should handle dev mode' do
      @core.instance_variable_set :@mode, :development
      @core.send(:default_setup).must_equal({
        'version' => 1,
        'aliases' => {},
        'compose_files' => ['docker-compose.development.yaml']
      })
    end

    it 'should handle prod mode' do
      @core.instance_variable_set :@mode, :production
      @core.send(:default_setup).must_equal({
        'version' => 1,
        'aliases' => {},
        'compose_files' => ['docker-compose.yaml']
      })
    end

    it 'should handle dev mode' do
      @core.instance_variable_set :@mode, :fake
      @core.send(:default_setup).must_equal({
        'version' => 1,
        'aliases' => {},
        'compose_files' => []
      })
    end
  end

  describe 'delete_alias' do
    it 'should delete alias' do
      config = {
        test: {
          'version' => 1,
          'compose_files' => ['my.yaml'],
          'aliases' => {
            'mine' => 'my fake alias'
          }
        }
      }
      @core.instance_variable_set :@cnfg, config
      @core.send :delete_alias, 'mine'
      @core.instance_variable_get(:@cnfg)[:test].must_equal({
        'version' => 1,
        'aliases' => {},
        'compose_files' => ['my.yaml']
      })
    end

    it 'should handle nonexistent alias' do
      config = {
        test: {
          'version' => 1,
          'compose_files' => ['my.yaml'],
          'aliases' => {
            'mine' => 'my fake alias'
          }
        }
      }
      @core.instance_variable_set :@cnfg, config
      mock = MiniTest::Mock.new
      mock.expect(:call, nil, ["No such alias 'yours'"])
      @core.stub(:bail, mock) do
        @core.send :delete_alias, 'yours'
        mock.verify
      end
    end
  end

  describe 'normalize' do
    it 'converts version 0' do
      input = %w[one two]
      version1 = {
        'version' => 1,
        'compose_files' => %w[one two],
        'aliases' => {}
      }
      @core.send(:normalize, input).must_equal version1
    end

    it 'pass-thru version 1' do
      input = {
        'version' => 1,
        'compose_files' => %w[one two],
        'aliases' => {}
      }
      @core.send(:normalize, input).must_equal input
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

    it 'handles -a (alias) flag' do
      @core.send(:parse_args, ['-a', 'mine', 'cmd']).must_equal [:add_alias, 'mine', 'cmd']
      assert_equal @core.instance_variable_get(:@mode), :development
    end

    it 'handles -a (alias) flag with -p' do
      @core.send(:parse_args, ['-p', '-a', 'mine', 'cmd']).must_equal [:add_alias, 'mine', 'cmd']
      assert_equal @core.instance_variable_get(:@mode), :production
    end

    it 'handles -a (alias) flag with -m' do
      @core.send(:parse_args, ['-m', 'yours', '-a', 'mine', 'cmd']).must_equal [:add_alias, 'mine', 'cmd']
      assert_equal @core.instance_variable_get(:@mode), :yours
    end

    it 'handles -d (delete alias) flag' do
      @core.send(:parse_args, ['-d', 'mine']).must_equal [:delete_alias, 'mine']
      assert_equal @core.instance_variable_get(:@mode), :development
    end

    it 'handles -d (delete alias) flag with -p' do
      @core.send(:parse_args, ['-p', '-d', 'mine']).must_equal [:delete_alias, 'mine']
      assert_equal @core.instance_variable_get(:@mode), :production
    end

    it 'handles -d (delete alias) flag with -m' do
      @core.send(:parse_args, ['-m', 'yours', '-d', 'mine']).must_equal [:delete_alias, 'mine']
      assert_equal @core.instance_variable_get(:@mode), :yours
    end

    it 'delegates to compose with -nc flag' do
      @core.send(:parse_args, ['-nc', 'passthru']).must_equal [:native, :compose, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :development
    end

    it 'delegates to docker with -nd flag' do
      @core.send(:parse_args, ['-nd', 'passthru']).must_equal [:native, :docker, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :development
    end

    it 'delegates to machine with -nm flag' do
      @core.send(:parse_args, ['-nm', 'passthru']).must_equal [:native, :machine, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :development
    end

    it 'delegates and sets mode' do
      @core.send(:parse_args, ['-p', '-nm', 'passthru']).must_equal [:native, :machine, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :production
    end

    it 'delegates and sets mode in other order' do
      @core.send(:parse_args, ['-nm', '-p', 'passthru']).must_equal [:native, :machine, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :production
    end

    it 'delegates and sets arbitrary mode' do
      @core.send(:parse_args, ['-nm', '-m', 'mine', 'passthru']).must_equal [:native, :machine, 'passthru']
      assert_equal @core.instance_variable_get(:@mode), :mine
    end
  end

  describe 'with_completion' do
    it 'STOP invokes container completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, 'words')
      @core.stub(:completion_containers, mock) do
        @core.send(:with_completion, ['stop'])
        mock.verify
      end
    end

    it 'IMAGES invokes image completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, 'words')
      @core.stub(:completion_images, mock) do
        @core.send(:with_completion, ['images'])
        mock.verify
      end
    end

    it 'PUSH invokes tagged image completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, 'words', [true])
      @core.stub(:completion_images, mock) do
        @core.send(:with_completion, ['push'])
        mock.verify
      end
    end

    it 'RMI invokes tagged image completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, 'words', [true])
      @core.stub(:completion_images, mock) do
        @core.send(:with_completion, ['rmi'])
        mock.verify
      end
    end

    it 'TAG invokes tagged image completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, 'words', [true])
      @core.stub(:completion_images, mock) do
        @core.send(:with_completion, ['tag'])
        mock.verify
      end
    end

    it 'SCP invokes machine completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, 'words')
      @core.stub(:completion_machines, mock) do
        @core.send(:with_completion, ['scp'])
        mock.verify
      end
    end

    it 'SSH invokes machine completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, 'words')
      @core.stub(:completion_machines, mock) do
        @core.send(:with_completion, ['ssh'])
        mock.verify
      end
    end

    it 'USE invokes machine completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, 'words')
      @core.stub(:completion_machines, mock) do
        @core.send(:with_completion, ['use'])
        mock.verify
      end
    end

    it 'BUILD invokes service completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, ['words'])
      @core.stub(:completion_services, mock) do
        @core.send(:with_completion, ['build'])
        mock.verify
      end
    end

    it 'LOGS invokes service completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, ['words'])
      @core.stub(:completion_services, mock) do
        @core.send(:with_completion, ['logs'])
        mock.verify
      end
    end

    it 'RUN invokes service completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, ['words'])
      @core.stub(:completion_services, mock) do
        @core.send(:with_completion, ['run'])
        mock.verify
      end
    end

    it 'UP invokes service completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, ['words'])
      @core.stub(:completion_services, mock) do
        @core.send(:with_completion, ['up'])
        mock.verify
      end
    end

    it 'otherwise invokes command completions' do
      mock = MiniTest::Mock.new
      mock.expect(:call, ['words'])
      @core.stub(:completion_commands, mock) do
        @core.send(:with_completion, [''])
        mock.verify
      end
    end
  end
end
