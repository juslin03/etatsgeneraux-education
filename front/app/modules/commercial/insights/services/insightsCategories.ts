import { API_PATH } from 'containers/App/constants';
import streams, { IStreamParams } from 'utils/streams';
import { IRelationship } from 'typings';
import { uuidRegExp } from 'utils/helperUtils';

export interface IInsightsCategoryData {
  id: string;
  type: string;
  attributes: {
    name: string;
    inputs_count: number;
  };
  relationships?: {
    view: {
      data: IRelationship;
    };
  };
}

export interface IInsightsCategory {
  data: IInsightsCategoryData;
}

export interface IInsightsCategories {
  data: IInsightsCategoryData[];
}

const getInsightsCategoriesEndpoint = (viewId: string) =>
  `insights/views/${viewId}/categories/`;

export function insightsCategoriesStream(
  insightsViewId: string,
  streamParams: IStreamParams | null = null
) {
  return streams.get<IInsightsCategories>({
    apiEndpoint: `${API_PATH}/${getInsightsCategoriesEndpoint(insightsViewId)}`,
    ...streamParams,
    cacheStream: false,
  });
}

export function insightsCategoryStream(
  insightsViewId: string,
  insightsCategoryId: string,
  streamParams: IStreamParams | null = null
) {
  return streams.get<IInsightsCategory>({
    apiEndpoint: `${API_PATH}/${getInsightsCategoriesEndpoint(
      insightsViewId
    )}/${insightsCategoryId}`,
    ...streamParams,
    cacheStream: false,
  });
}

export function addInsightsCategory(insightsViewId: string, name: string) {
  return streams.add<IInsightsCategory>(
    `${API_PATH}/${getInsightsCategoriesEndpoint(insightsViewId)}`,
    {
      category: { name },
    }
  );
}

export function updateInsightsCategory(
  insightsViewId: string,
  insightsCategoryId: string,
  name: string
) {
  return streams.update<IInsightsCategories>(
    `${API_PATH}/${getInsightsCategoriesEndpoint(
      insightsViewId
    )}/${insightsCategoryId}`,
    insightsCategoryId,
    { category: { name } }
  );
}

export async function deleteInsightsCategories(insightsViewId: string) {
  const response = await streams.delete(
    `${API_PATH}/${getInsightsCategoriesEndpoint(insightsViewId)}`,
    ''
  );

  const categoriesEndpointRegexp = new RegExp(
    `\/insights\/views\/${uuidRegExp}\/categories$`
  );
  const inputsEndpointRegexp = new RegExp(
    `\/insights\/views\/${uuidRegExp}\/inputs$`
  );

  await streams.fetchAllWith({
    regexApiEndpoint: [categoriesEndpointRegexp, inputsEndpointRegexp],
    onlyFetchActiveStreams: true,
  });

  return response;
}

export function deleteInsightsCategory(
  insightsViewId: string,
  insightsCategoryId: string
) {
  return streams.delete(
    `${API_PATH}/${getInsightsCategoriesEndpoint(
      insightsViewId
    )}/${insightsCategoryId}`,
    insightsCategoryId
  );
}
