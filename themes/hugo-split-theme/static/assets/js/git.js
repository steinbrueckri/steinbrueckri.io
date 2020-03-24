// Helper
const dom = {
	select: document.querySelector.bind(document),
	slectAll: document.querySelectorAll.bind(document)
};

const injectScript = (source, callback) => {
	const script = document.createElement('script');
	script.src = source;
	script.addEventListener('load', callback);
	document.head.appendChild(script);
};

const insertHypenationHintsForCamelCase = string => string.replace(/([a-z])([A-Z])/g, '$1\u00AD$2');

// Latest GitHub commit
(async () => {
	const username = 'steinbrueckri';
	const email = 'richard.steinbrueck@googlemail.com';

	const response = await fetch(`https://api.github.com/users/${username}/events/public`);
	const json = await response.json();

	// TODO: Support pagination if no suitable event can be found in the first request:
	// https://developer.github.com/v3/activity/events/#list-public-events-performed-by-a-user
	let latestCommit;
	const latestPushEvent = json.find(event => {
		if (event.type !== 'PushEvent') {
			return false;
		}

		// Ensure the commit is authored by me and I'm not just a "committer"
		latestCommit = event.payload.commits.reverse().find(commit => commit.author.email === email);
		return Boolean(latestCommit);
	});

	if (!latestCommit) {
		dom.select('#latest-commit').textContent = 'No commit';
		return;
	}

	const {repo, created_at: createdAt} = latestPushEvent;
	const repoUrl = `https://github.com/${repo.name}`;

	const commitTitleElement = dom.select('#latest-commit .commit-title');
	commitTitleElement.href = `${repoUrl}/commit/${latestCommit.sha}`;
	const commitMessageLines = latestCommit.message.trim().split('\n');
	commitTitleElement.title = commitMessageLines.slice(1).join('\n').trim();
	commitTitleElement.textContent = commitMessageLines[0].trim();

	const commitDateElement = dom.select('#latest-commit .commit-date');
	commitDateElement.textContent = timeago().format(createdAt);	

	const repoTitleElement = dom.select('#latest-commit .repo-title');
	repoTitleElement.href = repoUrl;
	repoTitleElement.textContent = repo.name;
})();
