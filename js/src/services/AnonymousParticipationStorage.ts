import { IEvent } from '@/types/event.model';

const ANONYMOUS_PARTICIPATIONS_LOCALSTORAGE_KEY = 'ANONYMOUS_PARTICIPATIONS';

interface IAnonymousParticipation {
  token: String;
  expiration: Date;
  confirmed: boolean;
}

class AnonymousParticipationNotFoundError extends Error {
  constructor(message?: string) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
    this.name = AnonymousParticipationNotFoundError.name;
  }
}

/**
 * Fetch existing anonymous participations saved inside this browser
 */
function getLocalAnonymousParticipations(): Map<String, IAnonymousParticipation> {
  return jsonToMap(localStorage.getItem(ANONYMOUS_PARTICIPATIONS_LOCALSTORAGE_KEY) || mapToJson(new Map()));
}

function mapToJson(map): string {
  return JSON.stringify([...map]);
}
function jsonToMap(jsonStr): Map<String, IAnonymousParticipation> {
  return new Map(JSON.parse(jsonStr));
}

/**
 * Purge participations which expiration has been reached
 * @param participations Map
 */
function purgeOldParticipations(participations: Map<String, IAnonymousParticipation>): Map<String, IAnonymousParticipation> {
  for (const [hashedUUID, { expiration }] of participations) {
    if (expiration < new Date()) {
      participations.delete(hashedUUID);
    }
  }
  return participations;
}

/**
 * Insert a participation in the list of anonymous participations
 * @param hashedUUID
 * @param participation
 */
function insertLocalAnonymousParticipation(hashedUUID: String, participation: IAnonymousParticipation) {
  const participations = purgeOldParticipations(getLocalAnonymousParticipations());
  participations.set(hashedUUID, participation);
  localStorage.setItem(ANONYMOUS_PARTICIPATIONS_LOCALSTORAGE_KEY, mapToJson(participations));
}

function buildExpiration(event: IEvent): Date {
  const expiration = event.endsOn || event.beginsOn;
  expiration.setMonth(expiration.getMonth() + 3);
  expiration.setDate(1);
  return expiration;
}

async function addLocalUnconfirmedAnonymousParticipation(event: IEvent, cancellationToken: string) {
    /**
     * We hash the event UUID so that we can't know which events an anonymous user goes by looking up it's localstorage
     */
  const hashedUUID = await digestMessage(event.uuid);

    /**
     * We round expiration to first day of next 3 months so that it's difficult to find event from date
     */
  const expiration = buildExpiration(event);
  insertLocalAnonymousParticipation(hashedUUID, { token: cancellationToken, expiration, confirmed: false });
}

async function confirmLocalAnonymousParticipation(uuid: String) {
  const participations = purgeOldParticipations(getLocalAnonymousParticipations());
  const hashedUUID = await digestMessage(uuid);
  const participation = participations.get(hashedUUID);
  if (participation) {
    participation.confirmed = true;
    participations.set(hashedUUID, participation);
    localStorage.setItem(ANONYMOUS_PARTICIPATIONS_LOCALSTORAGE_KEY, mapToJson(participations));
  }
}

async function isParticipatingInThisEvent(eventUUID: String): Promise<boolean> {
  const participation = await getParticipation(eventUUID);
  return participation !== undefined && participation.confirmed;
}

async function getParticipation(eventUUID: String): Promise<IAnonymousParticipation> {
  const hashedUUID = await digestMessage(eventUUID);
  const participation = purgeOldParticipations(getLocalAnonymousParticipations()).get(hashedUUID);
  if (participation) {
    return participation;
  }
  throw new AnonymousParticipationNotFoundError('Participation not found');
}

async function getLeaveTokenForParticipation(eventUUID: String): Promise<String> {
  return (await getParticipation(eventUUID)).token;
}

async function removeAnonymousParticipation(eventUUID: String): Promise<void> {
  const hashedUUID = await digestMessage(eventUUID);
  const participations = purgeOldParticipations(getLocalAnonymousParticipations());
  participations.delete(hashedUUID);
  localStorage.setItem(ANONYMOUS_PARTICIPATIONS_LOCALSTORAGE_KEY, mapToJson(participations));
}

async function digestMessage(message): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

export {
  addLocalUnconfirmedAnonymousParticipation,
  confirmLocalAnonymousParticipation,
  getLeaveTokenForParticipation,
  isParticipatingInThisEvent,
  removeAnonymousParticipation,
  AnonymousParticipationNotFoundError,
};
