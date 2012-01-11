require 'yaml'

class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[key.to_sym] = value
      options
    end
  end
end

class ConfigurationFileMissing < StandardError 
  def initialize(config_file)
    msg = "Configuration file #{config_file.inspect} is missing."
    super(msg)
  end
end

class CantReadConfigurationFile < StandardError
  def initialize(config_file)
    msg = "Can't read configuration file #{config_file.inspect} (check permissions)."
    super(msg)
  end
end  

class ConfigurationFileFormatError < StandardError
  def initialize(config_file)
    msg = "Configuration file #{config_file.inspect} has problems. It might be empty or in the wrong format."
    super(msg)
  end    
end

class ConfigurationFileInterpolationError < StandardError
  def initialize(config_file, field, interpolated_key)
    msg = "Configuration file #{config_file.inspect}: field '#{field}' has problems. It tries to interpolate string with non existant field '#{interpolated_key}'."
    super(msg)
  end    
end


class ConfigurationFile

  attr_reader :options, :config_file
  
  def initialize(config_file)
    @config_file = File.expand_path(config_file)
    raise ConfigurationFileMissing.new(config_file) unless FileTest::exists?(config_file)
    raise CantReadConfigurationFile.new(config_file) unless FileTest::readable?(config_file)
    if opts = YAML.load_file(config_file)
      @options = parse_options(opts)
    else
      raise ConfigurationFileFormatError.new(config_file)
    end    
  end
  
  def method_missing(meth, *anything)
    return options[meth] if options.has_key?(meth)
    super
  end
  
  def parse_options(hsh)
    opts = enrich_options(hsh).symbolize_keys
    opts.each do |(k,v)|
      next unless v.is_a? String      
      opts[k] = interpolate(opts, k, v)
    end
    opts
  end
  
  def enrich_options(opts)
    defaults = Hash.new
    defaults[:rails_root] = RAILS_ROOT if defined? RAILS_ROOT
    defaults.update(opts)
  end
  
  def interpolate(hsh, field, str)
    str.gsub(/#\{(.+?)\}/) do |s|
      sym = $1.intern
      if hsh.has_key?(sym)
        interpolate(hsh, field, hsh[sym])
      else
        raise ConfigurationFileInterpolationError.new(@config_file, field, sym)
      end
    end
  end
  
  def inspect
    "#<ConfigurationFile: #{@options.inspect}>"
  end
  
end
