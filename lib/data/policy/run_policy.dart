const resumeWindow = Duration(hours: 3);

bool canResumeRun(DateTime startedAt, DateTime now) =>
    now.difference(startedAt) <= resumeWindow;
