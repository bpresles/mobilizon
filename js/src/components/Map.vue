<template>
    <div class="map-container" v-if="config">
        <l-map
                :zoom="mergedOptions.zoom"
                :style="`height: ${mergedOptions.height}; width: ${mergedOptions.width}`"
                class="leaflet-map"
                :center="[lat, lon]"
                @click="clickMap"
                @update:zoom="updateZoom"
        >
            <l-tile-layer
                    :url="config.maps.tiles.endpoint"
                    :attribution="attribution"
            >

            </l-tile-layer>
            <v-locatecontrol :options="{icon: 'mdi mdi-map-marker'}"/>
            <l-marker :lat-lng="[lat, lon]" @add="openPopup" @update:latLng="updateDraggableMarkerPosition" :draggable="!readOnly">
                <l-popup v-if="popupMultiLine">
                    <span v-for="line in popupMultiLine" :key="line">{{ line }}<br /></span>
                </l-popup>
            </l-marker>
        </l-map>
    </div>
</template>

<script lang="ts">
import { Icon, LatLng, LeafletMouseEvent } from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Component, Prop, Vue } from 'vue-property-decorator';
import { LMap, LTileLayer, LMarker, LPopup, LIcon } from 'vue2-leaflet';
import Vue2LeafletLocateControl from '@/components/Map/Vue2LeafletLocateControl.vue';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';

@Component({
  components: { LTileLayer, LMap, LMarker, LPopup, LIcon, 'v-locatecontrol': Vue2LeafletLocateControl },
  apollo: {
    config: CONFIG,
  },
})
export default class Map extends Vue {
  @Prop({ type: Boolean, required: false, default: true }) readOnly!: boolean;
  @Prop({ type: String, required: true }) coords!: string;
  @Prop({ type: Object, required: false }) marker!: { text: String|String[], icon: String };
  @Prop({ type: Object, required: false }) options!: object;
  @Prop({ type: Function, required: false, default: () => {} }) updateDraggableMarkerCallback!: Function;

  defaultOptions: {
    zoom: Number;
    height: String;
    width: String;
  } = {
    zoom: 15,
    height: '100%',
    width: '100%',
  };

  zoom = this.defaultOptions.zoom;
  config!: IConfig;

  mounted() {
    // this part resolve an issue where the markers would not appear
    // @ts-ignore
    delete Icon.Default.prototype._getIconUrl;

    Icon.Default.mergeOptions({
      iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
      iconUrl: require('leaflet/dist/images/marker-icon.png'),
      shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
    });
  }

  openPopup(event) {
    this.$nextTick(() => {
      event.target.openPopup();
    });
  }

  get mergedOptions(): object {
    return { ...this.defaultOptions, ...this.options };
  }

  get lat() { return this.$props.coords.split(';')[1]; }
  get lon() { return this.$props.coords.split(';')[0]; }

  get popupMultiLine() {
    if (Array.isArray(this.marker.text)) {
      return this.marker.text;
    }
    return [this.marker.text];
  }

  clickMap(event: LeafletMouseEvent) {
    this.updateDraggableMarkerPosition(event.latlng);
  }

  updateDraggableMarkerPosition(e: LatLng) {
    this.updateDraggableMarkerCallback(e, this.zoom);
  }

  updateZoom(zoom: Number) {
    this.zoom = zoom;
  }

  get attribution() {
    return this.config.maps.tiles.attribution || this.$t('© The OpenStreetMap Contributors');
  }
}
</script>
<style lang="scss" scoped>
    div.map-container {
        height: 100%;
        width: 100%;

        .leaflet-map {
            z-index: 20;
        }
    }
</style>
