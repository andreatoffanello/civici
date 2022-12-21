<script setup>
import { onMounted, watch } from '@vue/runtime-core';
import mapboxgl from 'mapbox-gl'; // or "const mapboxgl = require('mapbox-gl');"
import { useStore } from '../stores/Store';
import { storeToRefs } from 'pinia';

const store = useStore()
const { selectedNum } = storeToRefs(store)

let map

const size = 150;
// This implements `StyleImageInterface`
// to draw a pulsing dot icon on the map.
const pulsingDot = {
	width: size,
	height: size,
	data: new Uint8Array(size * size * 4),

	// When the layer is added to the map,
	// get the rendering context for the map canvas.
	onAdd: function () {
		const canvas = document.createElement('canvas');
		canvas.width = this.width;
		canvas.height = this.height;
		this.context = canvas.getContext('2d');
	},

	// Call once before every frame where the icon will be used.
	render: function () {
		const duration = 1000;
		const t = (performance.now() % duration) / duration;

		const radius = (size / 2) * 0.3;
		const outerRadius = (size / 2) * 0.7 * t + radius;
		const context = this.context;

		// Draw the outer circle.
		context.clearRect(0, 0, this.width, this.height);
		context.beginPath();
		context.arc(
			this.width / 2,
			this.height / 2,
			outerRadius,
			0,
			Math.PI * 2
		);
		context.fillStyle = `rgba(255, 200, 200, ${1 - t})`;
		context.fill();

		// Draw the inner circle.
		context.beginPath();
		context.arc(
			this.width / 2,
			this.height / 2,
			radius,
			0,
			Math.PI * 2
		);
		context.fillStyle = 'rgba(255, 100, 100, 1)';
		context.strokeStyle = 'white';
		context.lineWidth = 4 + 4 * (1 - t);
		context.fill();
		context.stroke();

		// Update this image's data with data from the canvas.
		this.data = context.getImageData(
			0,
			0,
			this.width,
			this.height
		).data;

		// Continuously repaint the map, resulting
		// in the smooth animation of the dot.
		map.triggerRepaint();

		// Return `true` to let the map know that the image was updated.
		return true;
	}
};

const initMap = () => {
	mapboxgl.accessToken = 'pk.eyJ1IjoiYW5kcmVhdG9mZmFuZWxsbyIsImEiOiJjajNweWwxdnYwMDNxMndxZHkwNTBieHJzIn0.5ZJqJs29sA9UNOxNr0Fq_A';

	map = new mapboxgl.Map({
		container: 'map', // container ID
		style: 'mapbox://styles/mapbox/light-v11', // style URL
		//center: [12.335890866252527,45.43778525602261], // starting position [lng, lat]
		center: [12.3, 45.4], // starting position [lng, lat]
		zoom: 12,
		antialias: true,
		bearing: 180, // starting zoom
	});

	map.on('style.load', () => {
		// Insert the layer beneath any symbol layer.
		const layers = map.getStyle().layers;

		const labelLayerId = layers.find(
			(layer) => layer.type === 'symbol' && layer.layout['text-field']
		).id;

		// The 'building' layer in the Mapbox Streets
		// vector tileset contains building height data
		// from OpenStreetMap.
		map.addLayer(
			{
				'id': 'add-3d-buildings',
				'source': 'composite',
				'source-layer': 'building',
				'filter': ['==', 'extrude', 'true'],
				'type': 'fill-extrusion',
				'minzoom': 15,
				'paint': {
					'fill-extrusion-color': '#aaa',

					// Use an 'interpolate' expression to
					// add a smooth transition effect to
					// the buildings as the user zooms in.
					'fill-extrusion-height': [
						'interpolate',
						['linear'],
						['zoom'],
						15,
						0,
						15.05,
						['get', 'height']
					],
					'fill-extrusion-base': [
						'interpolate',
						['linear'],
						['zoom'],
						15,
						0,
						15.05,
						['get', 'min_height']
					],
					'fill-extrusion-opacity': 0.6
				}
			},
			labelLayerId
		);

		map.addControl(
			new mapboxgl.GeolocateControl({
				positionOptions: {
					enableHighAccuracy: true
				},
				// When active the map will receive updates to the device's location as it changes.
				trackUserLocation: true,
				// Draw an arrow next to the location dot to indicate which direction the device is heading.
				showUserHeading: true
			})
		);
	})
}

onMounted(() => {
	initMap()
})

watch(selectedNum, (num) => {

	map.flyTo({
		center: [num.lng, num.lat],
		zoom: 18,
		duration: 12000,
		essential: true,
		bearing: 0,
		pitch: 44
	});

	map.addImage('pulsing-dot', pulsingDot, { pixelRatio: 2 });

	map.addSource('point', {
		'type': 'geojson',
		'data': {
			'type': 'FeatureCollection',
			'features': [
				{
					'type': 'Feature',
					'geometry': {
						'type': 'Point',
						'coordinates': [num.lng, num.lat]
					},
					'properties': {
						'title': num.id
					}
				}
			]
		}
	});

	map.addLayer({
		'id': 'point',
		'type': 'symbol',
		'source': 'point',
		'layout': {
			'icon-image': 'pulsing-dot',
			// 'icon-size': 0.5,
			// 'icon-offset': [0, -40],
			// get the title name from the source's "title" property
			'text-field': ['get', 'title'],
			'text-font': [
				'Open Sans Semibold',
				'Arial Unicode MS Bold'
			],
			'text-offset': [0, 1],
			'text-anchor': 'top'
		}
	});

	// map.loadImage(
	// 	'/images/pin.png',
	// 	(error, image) => {
	// 		if (error) throw error;
	// 		map.addImage('custom-marker', image);

	// 		map.addSource('point', {
	// 			'type': 'geojson',
	// 			'data': {
	// 				'type': 'FeatureCollection',
	// 				'features': [
	// 					{
	// 						'type': 'Feature',
	// 						'geometry': {
	// 							'type': 'Point',
	// 							'coordinates': [num.lng, num.lat]
	// 						},
	// 						'properties': {
	// 							'title': num.id
	// 						}
	// 					}
	// 				]
	// 			}
	// 		});

	// 		// Add a symbol layer
	// 		map.addLayer({
	// 			'id': 'point',
	// 			'type': 'symbol',
	// 			'source': 'point',
	// 			'layout': {
	// 				'icon-image': 'custom-marker',
	// 				'icon-size': 0.5,
	// 				'icon-offset': [0, -40],
	// 				// get the title name from the source's "title" property
	// 				'text-field': ['get', 'title'],
	// 				'text-font': [
	// 					'Open Sans Semibold',
	// 					'Arial Unicode MS Bold'
	// 				],
	// 				'text-offset': [0, 1],
	// 				'text-anchor': 'top'
	// 			}
	// 		});
	// 	}
	// );
})



</script>

<template>

<div id="map"></div>

</template>

<style lang="scss">

#map {
	position: absolute;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
    opacity: 0;
}

</style>