#!/usr/bin/env python

import falcon
from falcon_cors import CORS
import json
from pathlib import Path
from tinydb import TinyDB, Query
import os
from subprocess import call

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


def getSheetJoinExercises(uid):
    sheet = sheets.get(eid=uid)
    sheet["exercises"] = list(map(
        lambda eid: getExercise(eid),
        sheet["content"]))
    sheet["uid"] = uid

    return sheet


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
        sheet = getSheetJoinExercises(uid)

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


class PdfSheetResource:

    @falcon.before(uidAsInt)
    def on_get(self, req, resp, uid):
        sheet = getSheetJoinExercises(uid)

        tempTitle = os.urandom(20)
        tempMd = "temp/{}.md".format(tempTitle)
        tempPdf = "temp/{}.pdf".format(tempTitle)

        def exoToStr(exo):
            return """
# {title}

{content}""".format(title=exo["title"], content=exo["text"])

        fullMarkdown = '\n\n'.join(map(exoToStr, sheet["exercises"]))

        with open(tempMd, "w") as file:
            file.write(fullMarkdown)

        call(["pandoc", tempMd, "--latex-engine=xelatex", "-o", tempPdf])

        # Return the resulting pdf to the client
        resp.status = falcon.HTTP_200
        resp.content_type = 'application/pdf'
        resp.stream = open(tempPdf, 'rb')
        resp.stream_len = os.path.getsize(tempPdf)
        #with open(tempPdf, 'r') as f:
        #    resp.body = f.read()


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
api.add_route('/render/sheet/{uid}', PdfSheetResource())
