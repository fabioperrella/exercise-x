require 'ruby_jard'

def debug(msg)
  return
  puts msg
end

def unique_values(arr)
  return 0 if arr.empty?

  distinct_elems = 1
  prev_index = 0
  index = 0
  prev_elem = arr[0]
  arr_size = arr.size

  while index < arr_size
    # jard
    prev_index = index
    index = index + (arr_size - index) / 2

    debug "arr: #{arr}, index: #{index}, prev_index: #{prev_index}, prev_elem: #{prev_elem}, current_elem: #{arr[index]}, distinct_elems: #{distinct_elems}"

    if arr[index] != prev_elem
      prev_elem = arr[index]

      if arr[index-1] == prev_elem
        debug "==> incr distinct_elems"
        distinct_elems += 1
      else
        debug "==> going to the left"
        index = prev_index + (index - prev_index) / 2
      end
    else
      prev_elem = arr[index]
      index += 1
    end
  end

  distinct_elems
end

def check(expected, output)
  if expected != output
    puts "failed, expected:#{expected}, output:#{output}"
  else
    puts "ok, expected: #{expected}, output: #{output}"
  end
end

arr = [1,1,1,1,1,1,1,1,2,2,2,2,3]
result = unique_values(arr)
check(3, result)

arr = []
result = unique_values(arr)
check(0, result)

arr = [1]
result = unique_values(arr)
check(1, result)

arr = [1,2]
result = unique_values(arr)
check(2, result)

arr = [0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4]
result = unique_values(arr)
check(5, result)
