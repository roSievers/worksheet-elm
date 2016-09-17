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


class ExerciseResource:

    @falcon.before(uidAsInt)
    def on_get(self, req, resp, uid):
        resp.body = json.dumps(getExercise(uid))

    @falcon.before(uidAsInt)
    def on_post(self, req, resp, uid):
        # TODO: verify mimetype

        inputJson = req.stream.read(4096).decode("utf-8")
        overflow = req.stream.read(1)
        if overflow:
            # 413 Payload Too Large
            raise falcon.HTTPError(
                falcon.HTTP_413, title="File exceeds size limit.")
        exercise = json.loads(inputJson)

        updateDict = {legalKey: exercise[legalKey]
                      for legalKey in ['title', 'text']}
        if uid == -1:
            if 'title' not in updateDict:
                raise falcon.HTTPError(
                    falcon.HTTP_422, title="Missing 'title' field.")
            if 'text' not in updateDict:
                raise falcon.HTTPError(
                    falcon.HTTP_422, title="Missing 'text' field.")
            uid = exercises.insert(updateDict)
        else:
            exercises.update(updateDict, eids=[uid])

        resp.body = json.dumps(getExercise(uid))
        resp.status = falcon.HTTP_201


class SheetResource:

    @falcon.before(uidAsInt)
    def on_get(self, req, resp, uid):
        sheet = sheets.get(eid=uid)
        sheet["exercises"] = list(map(
            lambda eid: getExercise(eid),
            sheet["content"]))

        resp.body = json.dumps(sheet)


class SheetListResource:

    def on_get(self, req, resp):
        allSheets = {"sheets": sheets.all()}

        for s in allSheets["sheets"]:
            del s["content"]
            s["uid"] = s.eid

        resp.body = json.dumps(allSheets)


cors = CORS(allow_all_origins=True, allow_all_methods=True)
api = falcon.API(middleware=[cors.middleware])

api.add_route('/api/exercise/{uid}', ExerciseResource())
api.add_route('/api/sheet/{uid}', SheetResource())
api.add_route('/api/sheets', SheetListResource())
