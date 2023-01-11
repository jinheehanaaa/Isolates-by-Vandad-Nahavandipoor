# Objective
- Isolates

# Note (Theory)
- Isolates are non-shared-memory threads of code that can run in parallel.
- Isolates are like processes.
- - Each isolate has its own memory pool and a single thread that has an event loop.
- Main event loop is usually dedicated to user-driven event (ex: user clicking, dragging, scrolling)
- Worker isolate is for heavy processing in the background
- Every isolate, upon finishing its work, can send an object back to its owner

# Note (Technical)
- SendPort is consumed by main function [2]
- Using <code>Isolate.exit</code> the memory is assigned to the receiving isolate and its complexity is O(1) 
- So you don't want to pass the big object from the main function of isolate to spawner. (Rarely used) <code>Isolate.spawn()</code>

# Tip
- COMMON MISTAKE: Don't parse json on main isolate.
- After async (data comes back), you can parse on main isolate.
- - (but since it's not user-initiated action, you may don't want to parse on main isolate.)
- Isolate.exit => pass value, not copy

# Flow
## Step 1: Communication b/w main function of isolate & isolate entrance (1 data)
- Main function: Send list of Persons <code>_getPersons(){}</code>
- Consumer function: Receive first data to Entrance function using Future & spawn <code>_getMessages(){}</code>

# Step 2: Stream
- Stream isolate: send the current date back to us 10 times in <code>Stream<String></code>
- Main function: Grab currnet date & time and send to the SendPort <code>_getMessages</code>
- Consumer function:  <code>getMessages</code> 
- - <code>.asStream</code>: Turn Future into isolate of Stream
- - <code>.asyncExpand</code>: Change data type to ReceivePort data type
- - <code>.takeWhile</code>: Condition for string
- - <code>.cast</code>: cast to Stream<String>

# Step 3:  1:12:45
- Main function: Make it return iterable value <code>_getPersons(){}</code>
- Entrance function: Accept the request & send msg <code>getPersons(){}</code>

# Resources
- [1][Isolates Tutorial](https://youtu.be/WCKmLQfpUEU)
- [2][Official Doc](https://api.flutter.dev/flutter/dart-isolate/SendPort/send.html)