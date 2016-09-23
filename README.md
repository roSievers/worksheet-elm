# Moni Worksheet

Moni Worksheet will be an exercise management system. It enables you
to enter math exercises and arrange them into exercise sheets.
The aim is to make it easier to reuse the exercises over different years/seminars.

Eventually the exercise sheets should be exported as TeX or PDF.

## Why build such a tool?

I often help organize preparatory seminars on a state level for students
participating in the Math Olympiad. We create exercise sheets building on
years of experience — which are scattered across a heterogeneous (chaotic)
directory structure and contained in latex files with various formating conventions.

I hope that by collecting all exercises in a central content management system
we will be able to spend less time on searching and typesetting and more time
on other aspects of running a seminar.

## Backend

It is using python+falcon+tinyDB as a backend for now which works quite nicely. The api is exposing a few routes like /api/exercise/{id} which support both get and post request to get and update data.

## The bad stuff

Unfortunately the synchronisation code isn't nice at all, this is my first Elm project. It is in a very early stage missing most features. (Like adding exercise sheets without hand editing the database file) Watching the ElmConf talks gave me some Ideas how to improve it, but that is still a while of.
