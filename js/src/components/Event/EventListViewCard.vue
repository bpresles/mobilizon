<docs>
A simple card for an event

```vue
<template>
  <div>
    <EventListViewCard
      :event="event"
      />
  </div>
</template>
<script>
export default {
  data() {
    return {
        event: {
          title: 'Vue Styleguidist first meetup: learn the basics!',
          id: 5,
          uuid: 'some uuid',
          beginsOn: new Date(),
          organizerActor: {
            preferredUsername: 'tcit',
            name: 'Some Random Dude',
            domain: null,
            id: 4,
            displayName() {
              return 'Some random dude'
            }
          },
          options: {
            maximumAttendeeCapacity: 4
          },
          participantStats: {
            approved: 1,
            notApproved: 2
          }
        }
      }
    }
  }
}
</script>
```
</docs>

<template>
  <article class="box">
    <div class="columns">
      <div class="content column">
        <div class="title-wrapper">
          <div class="date-component">
            <date-calendar-icon :date="event.beginsOn" />
          </div>
          <router-link :to="{ name: RouteName.EVENT, params: { uuid: event.uuid } }"><h2 class="title">{{ event.title }}</h2></router-link>
        </div>
        <div class="participation-actor has-text-grey">
          <span v-if="event.physicalAddress && event.physicalAddress.locality">{{ event.physicalAddress.locality }}</span>
          <span>
            <span>{{ $t('Organized by {name}', { name: event.organizerActor.displayName() } ) }}</span>
          </span>
        </div>
        <div class="columns">
          <span class="column is-narrow">
            <b-icon icon="earth" v-if="event.visibility === EventVisibility.PUBLIC" />
            <b-icon icon="lock-open" v-if="event.visibility === EventVisibility.UNLISTED" />
            <b-icon icon="lock" v-if="event.visibility === EventVisibility.PRIVATE" />
          </span>
          <span class="column is-narrow participant-stats">
            <span v-if="event.options.maximumAttendeeCapacity !== 0">
              {{ $t('{approved} / {total} seats', {approved: event.participantStats.participant, total: event.options.maximumAttendeeCapacity }) }}
            </span>
            <span v-else>
              {{ $tc('{count} participants', event.participantStats.participant, { count: event.participantStats.participant })}}
            </span>
          </span>
        </div>
      </div>
    </div>
    </article>
</template>

<script lang="ts">
import { IParticipant, ParticipantRole, EventVisibility, IEventCardOptions } from '@/types/event.model';
import { Component, Prop } from 'vue-property-decorator';
import DateCalendarIcon from '@/components/Event/DateCalendarIcon.vue';
import { IPerson } from '@/types/actor';
import { mixins } from 'vue-class-component';
import ActorMixin from '@/mixins/actor';
import { CURRENT_ACTOR_CLIENT } from '@/graphql/actor';
import EventMixin from '@/mixins/event';
import { RouteName } from '@/router';
import { changeIdentity } from '@/utils/auth';
import { Route } from 'vue-router';

const defaultOptions: IEventCardOptions = {
  hideDate: true,
  loggedPerson: false,
  hideDetails: false,
  organizerActor: null,
};

@Component({
  components: {
    DateCalendarIcon,
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
})
export default class EventListViewCard extends mixins(ActorMixin, EventMixin) {
  /**
   * The participation associated
   */
  @Prop({ required: true }) event!: IParticipant;
  /**
   * Options are merged with default options
   */
  @Prop({ required: false, default: () => defaultOptions }) options!: IEventCardOptions;

  currentActor!: IPerson;

  ParticipantRole = ParticipantRole;
  EventVisibility = EventVisibility;
  RouteName = RouteName;

}
</script>

<style lang="scss" scoped>
  @import "../../variables";

  article.box {
    div.content {
      padding: 5px;

      .participation-actor span, .participant-stats span {
        padding: 0 5px;

        button {
          height: auto;
          padding-top: 0;
        }
      }

      div.title-wrapper {
        display: flex;
        align-items: center;

        div.date-component {
          flex: 0;
          margin-right: 16px;
        }

        .title {
          display: -webkit-box;
          -webkit-line-clamp: 1;
          -webkit-box-orient: vertical;
          overflow: hidden;
          font-weight: 400;
          line-height: 1em;
          font-size: 1.6em;
          padding-bottom: 5px;
          margin: auto 0;
        }
      }
    }
  }

</style>
