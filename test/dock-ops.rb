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

  describe 'build' do
    it 'handles empty input' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml build '])
      @dock.stub(:sys, mock_sys) do
        @dock.build
        mock_sys.verify
      end
    end
  end

  describe 'config' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml config '])
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

  describe 'logs' do
    it 'handles empty input' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml logs '])
      @dock.stub(:sys, mock_sys) do
        @dock.logs
        mock_sys.verify
      end
    end
  end

  describe 'ps' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker ps '])
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

  describe 'pull' do
    it 'handles empty input' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker pull '])
      @dock.stub(:sys, mock_sys) do
        @dock.pull
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

  describe 'push' do
    it 'handles empty input' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker push '])
      @dock.stub(:sys, mock_sys) do
        @dock.push
        mock_sys.verify
      end
    end
  end

  describe 'rls' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-machine ls '])
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

  describe 'rmi' do
    it 'handles empty input' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker rmi '])
      @dock.stub(:sys, mock_sys) do
        @dock.rmi
        mock_sys.verify
      end
    end
  end

  describe 'run' do
    it 'invokes correct command' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml run --rm this'])
      @dock.stub(:sys, mock_sys) do
        @dock.run 'this'
        mock_sys.verify
      end
    end
  end

  describe 'run' do
    it 'handles empty input' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml run --rm'])
      @dock.stub(:sys, mock_sys) do
        @dock.run
        mock_sys.verify
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

  describe 'scp' do
    it 'handles empty input' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-machine scp '])
      @dock.stub(:sys, mock_sys) do
        @dock.scp
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

  describe 'ssh' do
    it 'handles empty input' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-machine ssh '])
      @dock.stub(:sys, mock_sys) do
        @dock.ssh
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

  describe 'stop' do
    it 'throws on empty input' do
      assert_raises BadArgsError do
        @dock.stop
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

  describe 'tag' do
    it 'handles empty input' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker tag '])
      @dock.stub(:sys, mock_sys) do
        @dock.tag
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

  describe 'up' do
    it 'handles empty input' do
      mock_sys = MiniTest::Mock.new
      mock_sys.expect(:call, nil, ['docker-compose -f my.yaml up '])
      @dock.stub(:sys, mock_sys) do
        @dock.up
        mock_sys.verify
      end
    end
  end

end
