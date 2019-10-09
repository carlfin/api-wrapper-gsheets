require 'lz4-ruby'
require 'active_support/core_ext/module'

class SheetdataIndex
  delegate :keys, :size, to: :raw_data

  def initialize(key = nil)
    @raw_data = key ? {} : []
    @key_column = key
  end

  attr_reader :key_column, :raw_data

  def append_data(block)
    if key_column
      block.each do |o|
        raw_data[o.delete_at(key_column)] = LZ4::compress(Marshal.dump(o))
      end
    else
      raw_data.push(LZ4::compress(Marshal.dump(block)))
    end
  end

  def each(&block)
    raw_data.each do |o|
      Marshal.load(LZ4::uncompress(o)).each do |row|
        yield row
      end
    end
  end

  def each_with_object(object, &block)
    raw_data.each do |o|
      Marshal.load(LZ4::uncompress(o)).each do |row|
        yield row, object
      end
    end
    object
  end

  def [](key)
    raise "unable to access by key!" unless key_column
    raw_data.each do |k, o|
      return Marshal.load(LZ4::uncompress(o)) if k == key
    end
    return nil
  end

  def shift
    updateable = Marshal.load(LZ4::uncompress(raw_data[0]))
    select = updateable.shift
    raw_data[0] = LZ4::compress(Marshal.dump(updateable))
    select
  end
end
