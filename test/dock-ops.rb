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
    config = {
      :test => ['my.yaml']
    }
    @dock.instance_variable_set :@cnfg, config
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
    it 'returns docker-compose command for single yaml' do
      @dock.send(:compose).must_equal 'docker-compose -f my.yaml'
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

  describe 'build' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml build this'])
      @dock.stub(:sys, mock_sys) do
        @dock.build 'this'
        mock_sys.verify
      end
    end
  end

  describe 'config' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml config'])
      @dock.stub(:sys, mock_sys) do
        @dock.config
        mock_sys.verify
      end
    end
  end

  describe 'down' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml down --remove-orphans'])
      @dock.stub(:sys, mock_sys) do
        @dock.down
        mock_sys.verify
      end
    end
  end

  describe 'images' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker images '])
      @dock.stub(:sys, mock_sys) do
        @dock.images
        mock_sys.verify
      end
    end
  end

  describe 'logs' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml logs this'])
      @dock.stub(:sys, mock_sys) do
        @dock.logs 'this'
        mock_sys.verify
      end
    end
  end

  describe 'ps' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker ps'])
      @dock.stub(:sys, mock_sys) do
        @dock.ps
        mock_sys.verify
      end
    end
  end

  describe 'pull' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker pull this:0.0.1'])
      @dock.stub(:sys, mock_sys) do
        @dock.pull 'this:0.0.1'
        mock_sys.verify
      end
    end
  end

  describe 'push' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker push repo/this:0.0.1'])
      @dock.stub(:sys, mock_sys) do
        @dock.push 'repo/this:0.0.1'
        mock_sys.verify
      end
    end
  end

  describe 'rls' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-machine ls'])
      @dock.stub(:sys, mock_sys) do
        @dock.rls
        mock_sys.verify
      end
    end
  end

  describe 'rmi' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker rmi this'])
      @dock.stub(:sys, mock_sys) do
        @dock.rmi 'this'
        mock_sys.verify
      end
    end
  end

  describe 'run' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml run --rm this '])
      mock_get_service = MiniTest::Mock.new
      mock_get_service.expect(:call, 'this', ['this'])
      @dock.stub(:get_service, mock_get_service) do
        @dock.stub(:sys, mock_sys) do
          @dock.run 'this'
          mock_get_service.verify
          mock_sys.verify
        end
      end
    end
  end

  describe 'scp' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-machine scp this'])
      @dock.stub(:sys, mock_sys) do
        @dock.scp 'this'
        mock_sys.verify
      end
    end
  end

  describe 'ssh' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-machine ssh this'])
      @dock.stub(:sys, mock_sys) do
        @dock.ssh 'this'
        mock_sys.verify
      end
    end
  end

  describe 'stop' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker stop this'])
      mock_container = MiniTest::Mock.new
      mock_container.expect(:call, 'this', ['this'])
      @dock.stub(:container, mock_container) do
        @dock.stub(:sys, mock_sys) do
          @dock.stop 'this'
          mock_container.verify
          mock_sys.verify
        end
      end
    end
  end

  describe 'tag' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker tag this that'])
      @dock.stub(:sys, mock_sys) do
        @dock.tag ['this', 'that']
        mock_sys.verify
      end
    end
  end

  describe 'up' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml up this'])
      @dock.stub(:sys, mock_sys) do
        @dock.up 'this'
        mock_sys.verify
      end
    end
  end


end
