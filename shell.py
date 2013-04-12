import datetime
from flask.ext.script import Manager
from app import app, models, db
import csv

manager = Manager(app)


@manager.command
def read_csv(user, project, price, csv_file):
    p = models.Project.query.filter_by(user_id=user, name=project).first()
    if not p:
        p = models.Project(name=project,
                           hourPrice=float(price),
                           archived=False,
                           user_id=user)
        db.session.add(p)
        db.session.commit()
    with open(csv_file, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for row in reader:
            (z, date, spent, text) = row
            (m, d, y) = date.split('/')

            e = models.Entry(text=text,
                             timeSpent=float(spent),
                             createdAt=datetime.date(int(y), int(m), int(d)),
                             project_id=p.id)
            db.session.add(e)
        db.session.commit()


if __name__ == "__main__":
    manager.run()