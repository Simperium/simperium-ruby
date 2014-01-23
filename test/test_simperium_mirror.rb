# require 'test/unit'
# # We shouldn't try to load an executable script
# # require 'simperium/listener-export-mongohq'

# @admin_key = ENV['SIMPERIUM_CLIENT_TEST_ADMINKEY']
# @appname = ENV['SIMPERIUM_CLIENT_TEST_APPNAME']

# class TestSimperiumMirror < Test::Unit::TestCase

#   # This test seems peculiar. simperium/listener-export-mongohq is written like
#   # an executable bin script but this test attemps to load it as a stadard .rb
#   # file which doesn't (and shouldn't) work.
#   #
#   # It then tries to call the executable script using a method (`mirror`) which
#   # doesn't actually exist on a module/class `Listener` which is never defined.
# 	def test_simperium_mirror
# 		Listener::mirror(@appname, @admin_key, 'todo')
# 	end
# end
