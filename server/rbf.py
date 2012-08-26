import webapp2

from google.appengine.ext import db
import random

class Circuit(db.Model):
  """Models an uploaded circuit."""
  cells = db.TextProperty()

class MainPage(webapp2.RequestHandler):
  def post(self):
      cells = self.request.get("cells")
      circuit = Circuit(cells=db.Text(cells))
      circuit.put()
  def get(self):
      circuits = Circuit.all()
      c = circuits[random.randrange(1, circuits.count())]
      self.response.headers['Content-Type'] = 'text/plain'
      self.response.write(c.cells)

app = webapp2.WSGIApplication([('/', MainPage)],
                              debug=True)
