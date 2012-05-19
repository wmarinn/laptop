--- IMAP Example widget
--
-- Example widget for the Awesome window manager
-- (http://awesome.naquadah.org)
--
-- Tested with Awesome 3.4
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- Less verbose mail widget displays unread inbox messages / total messages
-- Becomes red when inbox messages are more than 0
-- Click to popup list of inbox messages
-- Change server options and USERNAME/PASSWORD below.

require("imap")

w_imap = wibox.widget.textbox()
w_imap.text = "Loading..."

-- Create new imap client object and connect to the server
--
-- The imap.new function takes 5 arguments: Server and port to
-- connect to, the SSL/TLS protocol to use for encryption, the
-- mailbox to check and the time-out value for the TCP
-- connection.
--
-- Only the server name or ip address is mandatory; by default
-- imap.lua connects to port 993 (aka imaps), uses "sslv3" as
-- encryption protocol, checks then Inbox and sets the
-- time-out value to 5 seconds.
--
-- If you don't want to use SSL/TLS encryption at all set the
-- 3rd argument to "none".
--
-- All methods return nil followed by a errormessage in case
-- something went wrong. If the connection was successfully
-- established it returns just true, so o_imap.errmsg is set
-- to nil. We store the error message (or nil in case of
-- success) to o_imap.errmsg to display possible errors in
-- w_imap.mouse_enter-function.
o_imap = imap.new("smtp.gmail.com", 993, "sslv3", "Inbox", 5)
_, o_imap.errmsg = o_imap:connect()

-- Load external file with user/pass information 
--
-- The login credentials for my imap account are defined in
-- this external file that never gets published.
imap_user = "waldirmarin@gmail.com"
imap_pass = "thayscar123A!@#"

-- Login using username and passowrd
_, o_imap.errmsg = o_imap:login(imap_user, imap_pass)

-- What to do when the mouse pointer hovers over the widget
--
-- If the last client operation failed, o_imap.errmsg is
-- non-nil and we display the error message using
-- naugthy.notify.
w_imap.mouse_enter = function ()
			if o_imap.errmsg then
			   o_imap.popup = naughty.notify(
			      { screen = mouse.screen,
				text = "<span color='red'>ERR: " .. awful.util.escape(o_imap.errmsg) .. "</span>" })
			end
		     end

w_imap.mouse_leave = function ()
			naughty.destroy(o_imap.popup)
		     end

-- What to do when we click on widget
w_imap:buttons(awful.util.table.join(
		  -- Left mouse button: Fetch information on
		  -- unread & recent messages and display them
		  -- using naughty.popup.
		  awful.button({ }, 1, function()
				    local messages = {}
				    local content = ""
				    -- The fetch function takes 3 optional arguments: fetch_recent (default:
				    -- true), fetch_unread (default: false) and fetch_all (default: false).
				    local res, msg = o_imap:fetch(true,true)
				    
				    if res then
				       -- On success fetch() returns a table with information on the messages
				       -- that matched the search criteria (unread/recent/total). A message
				       -- information is represented as a table with the keys size, from and
				       -- subject that contain the message's size, from and subject header.
				       --
				       -- ! Please not that imap.lua does not (yet?) decode encoded from or
				       -- ! subject headers.
				       local k,v
				       for k,v in pairs(msg) do
					  table.insert(messages, v.size .. " " .. v.from .. " " .. v.subject)
				       end
				       
				       -- Now assemble the content to be displayed by the popup. Couldn't think
				       -- of a better way to avoid a newline at the last line: So each line ist
				       -- stored in a table that es afterwards joined to a string.
				       local i
				       for i = 1, #messages do
					  content = content .. messages[i]
					  if i < #messages then content = content .. "\n" end
				       end
				       
				       if #messages == 0 then content = "\t--Empty--" end
				       
				       content = awful.util.escape(content)
				       o_imap.popup = naughty.notify(
					  { title = "<span color='green'>" .. o_imap.server .. ":" .. o_imap.port .. "</span>",
					    text = content, 
					    screen = mouse.screen,
					    height = 400,
					    width = 600 })
				    else
				       -- If fetch was not successful, save the error message.
				       o_imap.errmsg = msg
				    end
				    
				 end),
		  
		  -- Right mouse button: Logout if the client is logged in and login, if the client is logged
		  -- out.
		  awful.button({ }, 3, function()
				    if o_imap.logged_in then
				       o_imap:logout()
				       w_imap.text = "-/-"
				    else
				       o_imap:connect()
				       o_imap:login(imap_user, imap_pass)
				       w_imap.text = "?/?"
				    end
				 end)
	       ))

-- Finally: Register a time to update mailbox information. Check once per minute seems okay.
mytimer = timer ({ timeout = 60 })
mytimer:connect_signal("timeout", function()
        if o_imap.logged_in then
				     -- The check() function returns a table with the number of unread, recent
				     -- and total messages in the mailbox.
				     --
				     -- In addition the imap library provides three separate functions that
				     -- return the number of total, unread and recent messages: o_imap:recent(),
				     -- o_imap:unread() and o_imap:total().
		    local res, msg = o_imap:check()
			o_imap.errmsg = msg
			if res then
                if res.unread > 0 then
                    w_imap.text = "<span color='red'><b>" .. res.unread .. "new mails" .. "</b></span>"
                else
                    w_imap.text = "No new mails."
                end
			else
                w_imap.text = "Error1."
			end
		else
		    if o_imap.errmsg then
				w_imap.text = "Error2."
                o_imap:connect()
	            o_imap:login(imap_user, imap_pass)
			else
			    w_imap.text = "No new mails.."
			end
		end
	end)
mytimer:start()
