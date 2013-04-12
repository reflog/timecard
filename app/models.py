from datetime import datetime, date
import json
import re
from app import db
from hashlib import md5


def to_json(inst, cls):
    """
    Jsonify the sql alchemy query result.
    """
    convert = dict()
    # add your coversions for things like datetime's
    # and what-not that aren't serializable.
    d = dict()
    for c in cls.__table__.columns:
        v = getattr(inst, c.name)
        if c.type in convert.keys() and v is not None:
            try:
                d[c.name] = convert[c.type](v)
            except:
                d[c.name] = "Error:  Failed to covert using ", str(convert[c.type])
        elif v is None:
            d[c.name] = str()
        else:
            d[c.name] = v
    return json.dumps(d)


class Project(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.Unicode, unique=True)
    hourPrice = db.Column(db.Float)
    archived = db.Column(db.Boolean, default=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    user = db.relationship('User', backref=db.backref('projects', lazy='dynamic', cascade="all,delete"))

    @property
    def public(self):
        return dict(
            name=self.name,
            hourPrice=self.hourPrice,
            id=self.id,
            archived=self.archived,
            entries=[e.public for e in self.entries]
        )


class Entry(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    text = db.Column(db.Unicode)
    timeSpent = db.Column(db.Float)
    createdAt = db.Column(db.DateTime)
    project_id = db.Column(db.Integer, db.ForeignKey('project.id'))
    project = db.relationship('Project', backref=db.backref('entries', lazy='dynamic', cascade="all,delete"))

    @property
    def public(self):
        return dict(
            text=self.text,
            createdAt=self.createdAt.isoformat(),
            id=self.id,
            timeSpent=self.timeSpent
        )


ROLE_USER = 0
ROLE_ADMIN = 1


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nickname = db.Column(db.String(64), unique=True)
    email = db.Column(db.String(120), index=True, unique=True)
    role = db.Column(db.SmallInteger, default=ROLE_USER)

    @staticmethod
    def make_valid_nickname(nickname):
        return re.sub('[^a-zA-Z0-9_\.]', '', nickname)

    @staticmethod
    def make_unique_nickname(nickname):
        new_nickname = ""
        if User.query.filter_by(nickname=nickname).first() is None:
            return nickname
        version = 2
        while True:
            new_nickname = nickname + str(version)
            if User.query.filter_by(nickname=new_nickname).first() is None:
                break
            version += 1
        return new_nickname

    def is_authenticated(self):
        return True

    def is_active(self):
        return True

    def is_anonymous(self):
        return False

    def get_id(self):
        return unicode(self.id)

    def avatar(self, w, h):
        return 'http://www.gravatar.com/avatar/%s?d=mm&s=%dx%d' % (md5(self.email).hexdigest(), w, h)

    def __repr__(self):  # pragma: no cover
        return '<User %r>' % self.nickname

# Create the database tables.
db.create_all()

