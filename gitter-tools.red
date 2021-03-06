Red []

do %gitter-api.red

init-gitter: does [
	do load %options.red
	user: gitter/user-info
	rooms: gitter/user-rooms user/id
	room: select-room rooms "red/red" ; Remove later
]

select-room: function [
	"Selects room by its name. Returns room ID."
	rooms "Block of rooms"
	name  "Name of room"
	/by	  "Select room by different field than name"
		field
] [
	unless by [field: 'name]
	foreach room rooms [if equal? name room/:field [return room]]
	none
]

list-rooms: function [
	rooms
] [
	foreach room rooms [
		print room/name
	]
]

strip-message: function [
	"Remove unnecessary informations from message"
	message
] [
	message/html: none
	message/author: any [all [message/fromUser message/fromUser/id] author]
	message/fromUser: none
	message/mentions: none
	message/urls: none
	message/issues: none
	message/unread: none
	message/readBy: none
	message/meta: none
]

download-all-messages: func [
	room
	/only "Remove some unnecessary fields"
	/to
		filename
] [
	unless exists? %messages/ [make-dir %messages/]
	unless to [
		filename: rejoin [%messages/ replace/all copy room/name #"/" #"-" %.red]
	]
	ret: gitter/get-messages room
	if empty? ret [
		; the room is empty
		write filename ""
		return none
	]
	if only [foreach message ret [strip-message message]]
	last-id: ret/1/id
	write filename mold/only reverse ret
	until [
		ret: gitter/get-messages/with room [beforeId: last-id]
		if only [foreach message ret [strip-message message]]
		unless empty? ret [
			last-id: ret/1/id
			write/append filename mold/only reverse ret
		]
		empty? ret
	]
]

select-message: function [
	"Select message by id"
	messages
	id
] [
	foreach message messages [
		if equal? id message/id [return message]
	]
	none
]

; --- searching

match-question: function [
	"Return LOGIC! value indicating whether message contains question mark."
	message
] [
	not not find message #"?"
]

get-code: function [
	"Returns block of code snippets or NONE"
	message
] [
	code: make block! 4
	fence: "```"
	parse message/text [
		some [
			thru fence
			copy value
			to fence
			3 skip
			(append code value)
		]
	]
	either empty? code [none] [code]
]

get-all-code: function [
	messages
] [
	code: make map! []
	foreach message messages [
		code/(message/id): get-code message
	]
	code
]

; ---

stats: function [
	messages
] [
	users: #()
	foreach message messages [
		user: message/fromUser/username
		unless users/:user [
			users/:user: 0
		]
		users/:user: users/:user + 1
	]
	users
]

maximum-of: function [
	series
] [
	max: first series
	pos: 1
	forall next series [
		if series/1 > max [
			max: series/1
			pos: index? series
		]
	]
	at series pos
]

probe-messages: function [
	messages
] [
	foreach message messages [
		print rejoin [message/fromUser/username " (" message/sent ") wrote:"]
		print "---------------------------------------------------------------"
		print message/text
		print "---------------------------------------------------------------"
		print ""
	]
]

probe-rooms: function [
	rooms
] [
	foreach room rooms [
		print rejoin [room/name ": #" room/id]
	]
]
