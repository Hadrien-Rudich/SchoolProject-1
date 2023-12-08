# Projet#1 - Système de vote

## Objectif

Un smart contract de vote pour une petite organisation avec les fonctionnalités suivantes:

- [x] Les électeurs sont ajoutés à une liste blanche
- [x] Les électeurs peuvent soumettre des propositions
- [x] Les électeurs peuvent voter pour une proposition
- [x] Les votes sont visibles de tous les électeurs
- [ ] La proposition gagnante est déterminée à la majorité simple
- [ ] Le code est sécurisé et respecte les ordres déterminés

## Processus de vote

1. [x] L'administrateur ajoute les électeurs à une liste blanche
2. [ ] L'administrateur débute la session d'enregistrement des propositions
3. [x] Les électeurs enregistrent leur(s) proposition(s)
4. [ ] L'administrateur met fin à la session d'enregistrement
5. [ ] L'administrateur débute la session de vote
6. [x] Les électeurs votent pour leur proposition préférée
7. [ ] L'administrateur met fin à la session de vote
8. [ ] L'administrateur comptabilise les votes
9. [x] La proposition gagnante est visible de tous

## Recommandations et exigences

- [x] Le smart contract doit utiliser la dernière version du compilateur
- [x] Le smart contract doit utiliser la librairie `Ownable` d'OpenZeppelin
- [x] Le smart contract doit être nommé `Voting`
- [x] Le smart contract doit définir les structures de données suivantes :

  ```solidity
  struct Voter {
      bool isRegistered;
      bool hasVoted;
      uint votedProposalId;
  }

  struct Proposal {
      string description;
      uint voteCount;
  }
  ```

- [x] Le smart contract doit définir un uint représentant la proposition gagnante :

  ```solidity
  uint winningProposalId
  ```

- [ ] ou bien une fonction `getWinner` qui retourne la proposition gagnante

- [x] Le smart contract doit définir une énumération représentant les étapes du vote comme suit :

  ```solidity
  enum WorkflowStatus {
      RegisteringVoters,
      ProposalsRegistrationStarted,
      ProposalsRegistrationEnded,
      VotingSessionStarted,
      VotingSessionEnded,
      VotesTallied
  }
  ```

- [x] Le smart contract doit définir une énumération représentant les étapes du vote comme suit :

  ```solidity
  event VoterRegistered(address voterAddress);
  event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
  event ProposalRegistered(uint proposalId);
  event Voted (address voter, uint proposalId);
  ```

- [x] L'administrateur doit déployer le smart contract

## Éléments de notation

> La réalisation stricte du cahier des charges avec une attention à la sécurité et une utilisation de tableau et de mapping vous permettra d'avoir 3/4
>
> Ce qui n'est pas précisé n'est pas demandé directement, mais chaque ajout sera lu. Ce sont ces ajouts et la pertinence de ceux ci qui vous permettront de viser 4. Le 4 est une note exceptionnelle.
>
> Pour répondre à vos doutes: si ce n'est pas précisé, ce n'est pas demandé (pour le 3/4). Donc oui il peut y avoir des ex aequo, l'administrateur peut éventuellement voter…
>
> Faites le projet pour avoir 3 , puis dupliquer le et envoyez un "votingPlus.sol" pour chercher le 4/4.
>
> Dans tous les cas, la note sera technique, mais aussi logique: certains parti pris doivent être raccords avec l'idée de la blockchain, et amener de la confiance.
>
> Nous noterons, et vous pourrez bien entendu revenir vers nous avec des commentaires pour qu'on comprenne mieux vos choix éventuels (et la note pourra ou non être modifiée).
>
> Bon courage à vous, et n'oubliez pas d'envoyer soumettre votre projet ici : https://formation.alyra.fr/products/developpeur-blockchain/categories/2149052575/posts/2153025116
