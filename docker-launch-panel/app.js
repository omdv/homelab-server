const express = require('express');
const morgan = require('morgan');
const {Docker} = require('node-docker-api');
const docker = new Docker({ socketPath: '/var/run/docker.sock' });
const path = require('path');

// Api
const app = express();

// Morgan
app.use(morgan('common'));
app.set("view engine", "pug");
app.set("views", path.join(__dirname, "views"));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', function (req, res) {
  docker.container.list()
    .then(containers => {
      let filtered = containers
        .filter(ct => ct.data.Labels["launchpanel.enabled"])
        .map(ft => ft.data)
        .map(ft => ({
          name: ft.Labels["launchpanel.name"],
          port: ft.Labels["launchpanel.port"],
          ip: ft.Labels["launchpanel.ip"],
          image: ft.Image,
          state: ft.State,
          status: ft.Status
        }));
      res.render('containers', {
        containers: filtered.sort(function(a, b) {
          return parseInt(a.port) - parseInt(b.port);
        })
      })
    })
    .catch(error => {
      res.send(error)
    })
})

app.get('/containers', function (req, res) {
  docker.container.list()
    .then(containers => {
      let filtered = containers
        .map(ft => ({
          all: ft.data
        }));
      res.send(filtered)
    })
    .catch(error => {
      res.send(error)
    })
})

//Launch listening server
const port = 8081;
app.listen(port, function () {
  console.log('app listening on port: ' + port)
})