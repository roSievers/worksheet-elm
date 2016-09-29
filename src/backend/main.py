#!/usr/bin/env python

import falcon
from falcon_cors import CORS
import json
from pathlib import Path
from tinydb import TinyDB, Query


db = TinyDB('db.json')

sheets = db.table("sheets")
exercises = db.table("exercises")


def uidAsInt(req, resp, resource, params):
    try:
        params['uid'] = int(params['uid'])
    except ValueError:
        raise falcon.HTTPBadRequest('Invalid ID',
                                    'ID was not valid.')


def getExercise(uid):
    exercise = exercises.get(eid=uid)
    exercise["uid"] = uid

    return exercise


def parseInputJSON(req, legalKeys, maxSize=4096):
    rawInput = req.stream.read(maxSize).decode("utf-8")
    overflow = req.stream.read(1)
    if overflow:
        # 413 Payload Too Large
        raise falcon.HTTPError(
            falcon.HTTP_413, title="File exceeds size limit.")
    rawJson = json.loads(rawInput)

    filteredJson = {}
    for legalKey in legalKeys:
        try:
            filteredJson[legalKey] = rawJson[legalKey]
        except KeyError:
            raise falcon.HTTPError(
                falcon.HTTP_422, title="Missing field.")

    return filteredJson


class ExerciseResource:

    @falcon.before(uidAsInt)
    def on_get(self, req, resp, uid):
        resp.body = json.dumps(getExercise(uid))

    @falcon.before(uidAsInt)
    def on_post(self, req, resp, uid):
        exercise = parseInputJSON(req, legalKeys=['title', 'text'])

        if uid < 0:
            uid = exercises.insert(exercise)
        else:
            exercises.update(exercise, eids=[uid])

        resp.body = json.dumps(getExercise(uid))
        resp.status = falcon.HTTP_201


class SheetResource:

    @falcon.before(uidAsInt)
    def on_get(self, req, resp, uid):
        sheet = sheets.get(eid=uid)
        sheet["exercises"] = list(map(
            lambda eid: getExercise(eid),
            sheet["content"]))
        sheet["uid"] = uid

        resp.body = json.dumps(sheet)

    @falcon.before(uidAsInt)
    def on_post(self, req, resp, uid):
        sheet = parseInputJSON(req, legalKeys=['title', 'content'])

        if uid == -1:
            uid = sheets.insert(sheet)
        else:
            sheets.update(sheet, eids=[uid])

        resp.body = json.dumps({"status": "ok"})
        resp.status = falcon.HTTP_201


class SheetListResource:

    def on_get(self, req, resp):
        allSheets = {"sheets": sheets.all()}

        for s in allSheets["sheets"]:
            del s["content"]
            s["uid"] = s.eid

        resp.body = json.dumps(allSheets)


class AllExercisesResource:

    def on_get(self, req, resp):
        allExercises = {"exercises": exercises.all()}

        for s in allExercises["exercises"]:
            s["uid"] = s.eid

        resp.body = json.dumps(allExercises)


cors = CORS(allow_all_origins=True, allow_all_methods=True)
api = falcon.API(middleware=[cors.middleware])

api.add_route('/api/exercise/{uid}', ExerciseResource())
api.add_route('/api/deprecated/exercises', AllExercisesResource())
api.add_route('/api/sheet/{uid}', SheetResource())
api.add_route('/api/sheets', SheetListResource())
