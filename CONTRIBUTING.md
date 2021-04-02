# Opening Pull Requests

Thanks for your interesting in contributing to Accessly; we appreciate it!

We can always use help documenting our code; we've added an inch-ci badge at the top of the readme that links to a page showing where undocumented code currently exists. We document using yard with markdown formatting.
This can be a great place to get started contributing because it gives you a chance to dive in and understand the code while documenting it.

Please consider starting a conversation in an issue before putting time into a non-trival PR to make sure the change tracks with the vision for the project.

Please squash the code in your PR down into a commit or commits with an appropriate messages before requesting review (or after making updates based on review).

Here are some tips on good commit messages:
[Thoughtbot](https://thoughtbot.com/blog/5-useful-tips-for-a-better-commit-message)
[Tim Pope](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)

Make sure that new code conforms to the style standards of the project and has test coverage.

Thanks for your help!

# Running Tests

Local tests rely on a postgres database. from a `psql` console on your local machine
1) Create the local 'aaa_test' database
```
CREATE DATABASE aaa_test;
```

2) Connect to the database
```
\c aaa_test;
```

3) From the root of the gem folder run
```
rake
```

