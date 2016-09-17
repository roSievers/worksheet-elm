# Run backend server
(cd src/backend && ./runBackend.sh &)

# Run frontend server
(cd src/frontend && pwd && ./runFrontend.sh &)

# In produtcion this can all be one server, as reactor isn't needed to constantly
# recompile changes in the elm code.
# http://stackoverflow.com/questions/34821974/how-to-serve-a-static-webpage-from-falcon-application
