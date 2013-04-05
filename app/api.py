from datetime import datetime
from flask.ext.login import current_user, login_required
from app import app, db
from flask import request, jsonify
from app.models import User, Project, Entry


def not_found(error=None):
    message = {
        'status': 404,
        'message': ('Not Found: ' + request.url) if not error else error,
    }
    resp = jsonify(message)
    resp.status_code = 404

    return resp


@app.route('/api/project', methods=['GET', 'POST'])
@login_required
def api_project_list():
    ret = {}

    if request.method == 'GET':
        ret['objects'] = [p.public for p in Project.query.filter_by(user=current_user)]
    elif request.method == 'POST':
        p = Project(name=request.json['name'],
                    hourPrice=request.json['hourPrice'],
                    archived=request.json['archived'],
                    user_id=current_user.get_id())
        db.session.add(p)
        db.session.commit()
        ret = p.public
    resp = jsonify(ret)
    resp.status_code = 200
    return resp

@app.route('/api/project/<int:projectId>', methods=['PATCH', 'DELETE'])
@login_required
def api_project(projectId):
    ret = {}
    p = Project.query.filter_by(user=current_user, id=projectId).first()
    if not p:
        return not_found("No such project!")

    if request.method == 'DELETE':
        db.session.delete(p)
        db.session.commit()
    resp = jsonify(ret)
    resp.status_code = 200
    return resp

@app.route('/api/project/<int:projectId>/entry', methods=['POST'])
@login_required
def api_entry(projectId):
    ret = {}
    p = Project.query.filter_by(user=current_user, id=projectId).first()
    if not p:
        return not_found("No such project!")
    if request.method == 'POST':
        e = Entry(text=request.json['text'],
                  timeSpent=request.json['timeSpent'],
                  createdAt=datetime.now(),
                  project_id=p.id)
        db.session.add(e)
        db.session.commit()
        ret = e.public
    resp = jsonify(ret)
    resp.status_code = 200
    return resp


@app.route('/api/project/<int:projectId>/entry/<int:entryId>', methods=['PATCH', 'DELETE'])
@login_required
def api_entry_edit(projectId, entryId):
    ret = {}
    p = Project.query.filter_by(user=current_user, id=projectId).first()
    if not p:
        return not_found("No such project!")
    if request.method == 'DELETE':
        e = Entry.query.filter_by(project=p, id=entryId).first()
        if not e:
            return not_found("No such entry!")
        db.session.delete(e)
        db.session.commit()
    resp = jsonify(ret)
    resp.status_code = 200
    return resp
