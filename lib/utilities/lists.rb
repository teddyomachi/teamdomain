# coding: utf-8

#
# list.rb : 連結リスト
#
#           Copyright (C) 2006 Makoto Hiroi
#

# セルの定義
class Cell
  attr_accessor :data, :link
  def initialize(data, link = nil)
    @data = data
    @link = link
  end
end

# operator overloads { <, <=, > }
def <(y)
  @data[:spin_id] < y[:spin_id]
end

def <=(y)
  (@data[:spin_id] < y[:spin_id] || @data[:spin_id] == y[:spin_id])
end

def >(y)
  @data[:spin_id] > y[:spin_id]
end

# 連結リスト
class List
  include Enumerable
  
  def initialize
    @root = Cell.new(nil)   # Header Cell をセット
  end
  
  # n 番目にデータを挿入する
  def insert(n, data)
    cp = @root
    while cp
      if n == 0
        cp.link = Cell.new(data, cp.link)
        return data
      end
      n -= 1
      cp = cp.link
    end
  end
  
  # n 番目のデータを求める
  def at(n)
    cp = @root.link
    while cp
      return cp.data if n == 0
      n -= 1
      cp = cp.link
    end
  end
  
  # n 番目のデータを削除する
  def delete(n)
    cp = @root
    while cp.link
      if n == 0
        data = cp.link.data
        cp.link = cp.link.link
        return data
      end
      n -= 1
      cp = cp.link
    end
  end
  
  # Enumerable 用
  def each
    cp = @root.link
    while cp
      yield cp.data
      cp = cp.link
    end
  end
  
  # 文字列に変換
  def to_s
    str = "("
    each do |x|
      str << x.to_s
      str << ","
    end
    if str[-1] == ?,
      str[-1] = ?)
    else
      str << ")"
    end
    str
  end
end

# ソート済み連結リスト
class SortedList < List
# operator overloads { <, <=, > }
  def <(y)
    @data[:spin_id] < y[:spin_id]
  end
  
  def <=(y)
    (@data[:spin_id] < y[:spin_id] || @data[:spin_id] == y[:spin_id])
  end
  
  def >(y)
    @data[:spin_id] > y[:spin_id]
  end
  
  def insert(data)
    cp = @root
    while cp.link
      break if data < cp.link.data
      cp = cp.link
    end
    cp.link = Cell.new(data, cp.link)
  end
end

# 自己組織化探索 (self-organizing search)
class SOList < List
  def find
    cp = @root
    while cp.link
      if yield cp.link.data
        # セルを先頭へ移動する (Move To Front)
        cp1 = cp.link
        cp.link = cp1.link
        cp1.link = @root.link
        @root.link = cp1
        return cp1.data
      end
      cp = cp.link
    end
  end
end

# 連結リストによるスタックの実装
class Stack
  attr_reader :size
  def initialize
    @size = 0
    @buff = List.new
  end
  
  # データを追加する
  def push(data)
    @size += 1
    @buff.insert(0, data)
  end
  
  # データを取り出す
  def pop
    @size -= 1
    @buff.delete(0)
  end
  
  # スタックは空か？
  def empty?
    @size == 0
  end
end

# 循環リストによるキューの実装
class Queue
  attr_reader :size
  def initialize
    @size = 0
    @rear = nil
  end
  
  # データを追加する
  def enqueue(data)
    if @rear
      cp = Cell.new(data, @rear.link)
      @rear.link = cp
      @rear = cp
    else
      @rear = Cell.new(data)
      @rear.link = @rear     # 循環リスト
    end
    @size += 1
    data
  end
  
  # データを取り出す
  def dequeue
    if @rear
      front = @rear.link     # @rear.link が front
      if front == @rear
        @rear = nil          # 最後の一つ
      else
        @rear.link = front.link
      end
      @size -= 1
      front.data
    end
  end
  
  # キューは空か？
  def empty?
    @size == 0
  end
end

# テスト
if __FILE__ == $0
  # スタックの動作
  a = Stack.new
  5.times do |x|
    print "push ", a.push(x), "\n"
  end
  while !a.empty?
    print "pop ", a.pop, "\n"
  end

  # キューの動作
  b = Queue.new
  5.times do |x|
    print "enqueue ", b.enqueue(x), "\n"
  end
  while !b.empty?
    print "dequeue ", b.dequeue, "\n"
  end
end