def get_total_time(arr)  
  # Write your code here  
  penalty = 0

  arr = arr.sort

  while arr.size > 1
    puts "arr: #{arr}, penalty: #{penalty}"
    item = arr.pop
    penalty += item + arr[-1]
    arr[-1] += item
  end

  penalty
end 

def check(expected, output)
  if expected != output
    puts "failed: #{expected} != #{output}"
  else
    puts 'ok'
  end
end


result = get_total_time([4, 2, 1, 3])
check(result, 26)

result = get_total_time([2, 3, 9, 8, 4])
check(result, 88)

result = get_total_time([2])
check(result, 0)

result = get_total_time([2,1])
check(result, 3)

