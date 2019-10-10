require 'lz4-ruby'
require 'active_support/core_ext/module'

module RowCrudGsheet
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
        block.each do |o|
          raw_data.push(LZ4::compress(Marshal.dump(o)))
        end
      end
    end

    def each(&block)
      raw_data.each do |o|
        data = o.is_a?(Array) ? o.last : o
        yield Marshal.load(LZ4::uncompress(data))
      end
    end

    def each_with_object(object, &block)
      raw_data.each_with_object do |o, object|
        data = o.is_a?(Array) ? o.last : o
        yield Marshal.load(LZ4::uncompress(data)), object
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
      Marshal.load(LZ4::uncompress(raw_data.shift))
    end
  end
end
