#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'inc.filter.rb'

class RemapClass
  @@index = 0

  def initialize(name)
    @name = name
    @filter = Filter.new()

    @code = {
      :initialize                      => '',
      :remap_key                       => '',
      :remap_consumer                  => '',
      :remap_pointing                  => '',
      :remap_setkeyboardtype           => '',
      :remap_simultaneouskeypresses    => '',
      :keycode                         => '',
      :statusmessage                   => '',

      :variable                        => [],
      :simultaneouskeypresses_variable => [],
    }
  end
  attr_accessor :name, :filter, :code

  def +(other)
    other.code.each do |k,v|
      @code[k] += v
    end
    self
  end

  # return true if 'line' contains autogen/filter definition.
  def parse(line)
    return true if @filter.parse(line)

    if /<autogen>--(.+?)-- (.+)<\/autogen>/ =~ line then
      operation = $1
      params = $2
      @@index += 1

      case operation
      when 'SetKeyboardType'
        @code[:remap_setkeyboardtype] += "keyboardType = #{params}.get();\n";

      when 'ShowStatusMessage'
        @code[:statusmessage] = "#{params};\n"

      when 'SimultaneousKeyPresses'
        @code[:keycode] += "VK_SIMULTANEOUSKEYPRESSES_#{name}_#{@@index} --AUTO--\n"
        $func[:simultaneouskeypresses] << name
        @code[:simultaneouskeypresses_variable] << { :name => "remap_#{@@index}_", :params => "KeyCode::VK_SIMULTANEOUSKEYPRESSES_#{name}_#{@@index}, #{params}" }
        @code[:remap_simultaneouskeypresses] += "remap_#{@@index}_.remap();\n"

      when 'KeyToKey'
        @code[:variable] << ['RemapUtil::KeyToKey', "value#{@@index}_"]
        @code[:remap_key] += "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'DoublePressModifier'
        @code[:variable] << ['DoublePressModifier', "value#{@@index}_"]
        @code[:remap_key] += "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'IgnoreMultipleSameKeyPress'
        @code[:variable] << ['IgnoreMultipleSameKeyPress', "value#{@@index}_"]
        @code[:remap_key] += "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'KeyToConsumer'
        @code[:variable] << ['RemapUtil::KeyToConsumer', "value#{@@index}_"]
        @code[:remap_key] += "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'KeyToPointingButton'
        @code[:variable] << ['RemapUtil::KeyToPointingButton', "value#{@@index}_"]
        @code[:remap_key] += "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'KeyOverlaidModifier'
        @code[:variable] << ['KeyOverlaidModifier', "value#{@@index}_"]
        @code[:remap_key] += "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'KeyOverlaidModifierWithRepeat'
        @code[:variable] << ['KeyOverlaidModifier', "value#{@@index}_"]
        @code[:remap_key] += "    if (value#{@@index}_.remapWithRepeat(remapParams, #{params})) break;\n"

      when 'ModifierHoldingKeyToKey'
        @code[:variable] << ['ModifierHoldingKeyToKey', "value#{@@index}_"]
        @code[:remap_key] += "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'HoldingKeyToKey'
        @code[:variable] << ['HoldingKeyToKey', "value#{@@index}_"]
        @code[:remap_key] += "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'ConsumerToKey'
        @code[:variable] << ['RemapUtil::ConsumerToKey', "value#{@@index}_"]
        @code[:remap_consumer] += "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'ConsumerToConsumer'
        @code[:variable] << ['RemapUtil::ConsumerToConsumer', "value#{@@index}_"]
        @code[:remap_consumer] += "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'PointingRelativeToScroll'
        @code[:variable] << ['RemapUtil::PointingRelativeToScroll', "value#{@@index}_"]
        @code[:remap_pointing] += "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'PointingButtonToPointingButton'
        @code[:variable] << ['RemapUtil::PointingButtonToPointingButton', "value#{@@index}_"]
        @code[:remap_pointing] << "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      when 'PointingButtonToKey'
        @code[:variable] << ['RemapUtil::PointingButtonToKey', "value#{@@index}_"]
        @code[:remap_pointing] << "    if (value#{@@index}_.remap(remapParams, #{params})) break;\n"

      else
        print "%%% ERROR #{type} %%%\n#{l}\n"
        exit 1
      end

      return true
    end

    return false
  end

  def fixup
    [:remap_key, :remap_consumer,:remap_pointing, :remap_simultaneouskeypresses].each do |k|
      unless @code[k].empty? then
        c  = "do {\n"
        c += @filter.to_code
        c += @code[k]
        c += "} while (false);\n"
        @code[k] = c
      end
    end
  end

  def empty?
    @code.each do |k, v|
      return false unless v.empty?
    end
    return true
  end

  def to_code
    return '' if empty?

    code  = "class RemapClass_#{@name} : public RemapClass {\n"
    code += "public:\n"

    code += "void initialize(void) {\n"
    code += @code[:initialize]
    unless @code[:statusmessage].empty? then
      code += "statusmessage = #{@code[:statusmessage]}"
    end
    code += "}\n"

    unless @code[:remap_setkeyboardtype].empty? then
      code += "void remap_setkeyboardtype(KeyboardType &keyboardType) {\n"
      code += @code[:remap_setkeyboardtype]
      code += "}\n"
    end
    unless @code[:remap_key].empty? then
      code += "void remap_key(RemapParams &remapParams) {\n"
      code += @code[:remap_key]
      code += "}\n"
    end
    unless @code[:remap_consumer].empty? then
      code += "void remap_consumer(RemapConsumerParams &remapParams) {\n"
      code += @code[:remap_consumer]
      code += "}\n"
    end
    unless @code[:remap_pointing].empty? then
      code += "void remap_pointing(RemapPointingParams_relative &remapParams) {\n"
      code += @code[:remap_pointing]
      code += "}\n"
    end

    # ----------------------------------------
    code   += "bool enabled(EnableType type) const {\n"
    if @code[:remap_setkeyboardtype].empty? then
      code += "if (type == ENABLE_TYPE_SETKEYBOARDTYPE) return false;\n"
    end
    if @code[:remap_key].empty? then
      code += "if (type == ENABLE_TYPE_KEY) return false;\n"
    end
    if @code[:remap_consumer].empty? then
      code += "if (type == ENABLE_TYPE_CONSUMER) return false;\n"
    end
    if @code[:remap_pointing].empty? then
      code += "if (type == ENABLE_TYPE_POINTING) return false;\n"
    end
    if @code[:statusmessage].empty? then
      code += "if (type == ENABLE_TYPE_STATUSMESSAGE) return false;\n"
    end

    if /^passthrough_/ =~ @name or @name == 'notsave_passthrough' then
      code += "return config.#{@name};\n"
    else
      code += "return config.#{@name} && ! config.notsave_passthrough;\n"
    end
    code   += "}\n"

    # ----------------------------------------
    code += "\n"
    code += "private:\n"
    @code[:variable].each do |variable|
      code += "  #{variable[0]} #{variable[1]};\n"
    end
    code += "};\n"

    code += "RemapClass_#{@name} remapclass_#{@name};\n"
    code += "\n\n"

    code
  end
end