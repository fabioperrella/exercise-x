require 'ruby_jard'

class Node < Struct.new(:data, :next, keyword_init: true)
  def even?
    data.even?
  end

  def to_a
    elems = [data]
    node = self
    while node = node.next
      elems << node.data
    end

    elems
  end
end

def createLinkedList(arr)
  prev_node = nil
  arr.reverse.each do |elem|
    node = Node.new(data: elem, next: prev_node)
    prev_node = node
    node
  end

  prev_node
end

# 1 -> 2 -> 8 -> 9 -> 12 -> 16
# 1 -> 2 <- 8    9 -> 12 -> 16
# 1 ->
# 1 -> 8 -> 2 -> 9 -> 16 -> 12
def reverse(head)
  first_even_elem = nil
  last_odd_elem = nil

  first_elem = Node.new(data: 1, next: head)
  prev_elem = first_elem

  # jard

  while head
    if head.even?
      if first_even_elem.nil?
        first_even_elem = head

        last_odd_elem = prev_elem
        prev_elem = head
        head = head.next
      else
        next_elem = head.next
        head.next = prev_elem

        prev_elem = head
        head = next_elem
      end
    else
      if first_even_elem
        first_even_elem.next = head
      end
      if last_odd_elem
        last_odd_elem.next = prev_elem
      end

      first_even_elem = nil
      last_odd_elem = nil
      prev_elem = head
      head = head.next
    end
  end

  if first_even_elem
    first_even_elem.next = head
  end
  if last_odd_elem
    last_odd_elem.next = prev_elem
  end

  first_elem.next
end

def check(expected, output)
  if expected != output
    puts "failed, expected:#{expected}, output:#{output}"
  else
    puts "ok, expected: #{expected}, output: #{output}"
  end
end

head_1 = createLinkedList([1, 2, 8, 9, 12, 16]);
expected_1 = createLinkedList([1, 8, 2, 9, 16, 12]);
output_1 = reverse(head_1);
check(expected_1.to_a, output_1.to_a);

head_2 = createLinkedList([2, 18, 24, 3, 5, 7, 9, 6, 12]);
expected_2 = createLinkedList([24, 18, 2, 3, 5, 7, 9, 12, 6]);
output_2 = reverse(head_2);
check(expected_2.to_a, output_2.to_a);

head_2 = createLinkedList([2, 8]);
expected_2 = createLinkedList([8, 2]);
output_2 = reverse(head_2);
check(expected_2.to_a, output_2.to_a);

head_2 = createLinkedList([1, 2, 8, 4, 3, 5, 2]);
expected_2 = createLinkedList([1, 4, 8, 2, 3, 5, 2]);
output_2 = reverse(head_2);
check(expected_2.to_a, output_2.to_a);

