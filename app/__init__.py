from os.path import dirname, abspath
from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy
from flask.ext.login import LoginManager
from flask.ext.openid import OpenID

ROOT = dirname(dirname(abspath(__file__)))

app = Flask(__name__)
app.config['SECRET_KEY'] = 'v12341f2323'
app.config['DEBUG'] = True
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///'+ROOT+'/timecard.db'
db = SQLAlchemy(app)
lm = LoginManager()
lm.init_app(app)
lm.login_view = 'login'
lm.login_message = 'Please log in to access this page.'
oid = OpenID(app, ROOT)
app.jinja_env.line_statement_prefix = '%'


#from flask.ext.debugtoolbar import DebugToolbarExtension
#flask.ext.debugtoolbar.DebugToolbarExtension(app)
from app import models, views, api
