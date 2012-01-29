require 'test/unit'
require 'configuration'
require 'fileutils'

class ConfigurationFileTest < Test::Unit::TestCase

  def setup
    @fixtures_path = File.expand_path File.join(File.dirname(__FILE__), "fixtures")
    @config_file = File.join @fixtures_path, "subversion.yaml"
    @broken_file = File.join @fixtures_path, "broken.yaml"    
    @unreadable_config_file = File.join @fixtures_path, "not-readable.yaml"
    @empty_config_file = File.join @fixtures_path, "empty.yaml"
  end
  
  def teardown
    FileUtils.rm_f(@unreadable_config_file)
  end
  
  def test_configuration
    assert_nothing_raised do
      @config = ConfigurationFile.new(@config_file)        
    end
    assert_instance_of ConfigurationFile, @config
    
    assert_instance_of Hash, @config.options    
    assert @config.options.has_key?(:storage_path)    
    assert @config.options.has_key?(:storage_uid)
    assert_instance_of Fixnum, @config.options[:storage_uid]
    assert_equal 502, @config.options[:storage_uid]
    assert_instance_of String, @config.inspect
    assert @config.inspect =~ /:storage_path/
  end
  
  ::RAILS_ROOT = "/tmp" unless defined? ::RAILS_ROOT
  
  def test_variables_interpolation
    @config = ConfigurationFile.new(@config_file)
    assert_equal "/var/spool", @config.options[:root]
    assert_equal "/var/spool/project_alpha.storage", @config.options[:storage_path]
    assert_equal "/tmp/something", @config.options[:rails_root_test]
  end
  
  def test_missing_interpolation
    assert_raises(ConfigurationFileInterpolationError) do
      @config = ConfigurationFile.new(@broken_file)
    end
  end
  
  def test_fancy_accessors
    @config = ConfigurationFile.new(@config_file)
    assert_nothing_raised do 
      assert_instance_of String, @config.storage_path
    end
    
    assert_raises(NoMethodError) do
      @config.something_not_in_config
    end    
  end
  
  def test_config_file_problems
    assert_raises(ConfigurationFileMissing) do
      @config = ConfigurationFile.new("/tmp/this-can-not-exist.if-it-is.it-is-miracle-#{rand(10000)}")        
    end
    
    assert_raises(CantReadConfigurationFile) do
      FileUtils.touch(@unreadable_config_file)
      FileUtils.chmod(0000, @unreadable_config_file)
      @config = ConfigurationFile.new(@unreadable_config_file)        
    end

    assert_raises(ConfigurationFileFormatError) do
      @config = ConfigurationFile.new(@empty_config_file)
    end    
  end  
  
end