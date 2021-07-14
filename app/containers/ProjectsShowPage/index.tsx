import React, { memo, useMemo } from 'react';
import { isError, isUndefined } from 'lodash-es';
import { isNilOrError, isApiError } from 'utils/helperUtils';
import { withRouter, WithRouterProps } from 'react-router';
import clHistory from 'utils/cl-router/history';

// components
import ProjectHelmet from './shared/header/ProjectHelmet';
import ProjectNotFound from './shared/header/ProjectNotFound';
import ProjectNotVisible from './shared/header/ProjectNotVisible';
import ProjectHeader from './shared/header/ProjectHeader';
import ProjectEvents from './shared/events';
import ContinuousIdeas from './continuous/Ideas';
import ContinuousSurvey from './continuous/Survey';
import ContinuousPoll from './continuous/Poll';
import ContinuousVolunteering from './continuous/Volunteering';
import TimelineContainer from './timeline';
import { Spinner } from 'cl2-component-library';
import ForbiddenRoute from 'components/routing/forbiddenRoute';

// hooks
import useLocale from 'hooks/useLocale';
import useAppConfiguration from 'hooks/useAppConfiguration';
import useProject from 'hooks/useProject';
import usePhases from 'hooks/usePhases';
import useEvents from 'hooks/useEvents';
import useAuthUser from 'hooks/useAuthUser';

// style
import styled from 'styled-components';
import { media, colors } from 'utils/styleUtils';

// typings
import { IProjectData } from 'services/projects';

const Container = styled.main<{ background: string }>`
  flex: 1 0 auto;
  height: 100%;
  min-height: calc(
    100vh - ${(props) => props.theme.menuHeight + props.theme.footerHeight}px
  );
  display: flex;
  flex-direction: column;
  align-items: center;
  background: ${(props) => props.background};

  ${media.smallerThanMaxTablet`
    min-height: calc(100vh - ${({ theme: { mobileMenuHeight } }) =>
      mobileMenuHeight}px - ${({ theme: { mobileTopBarHeight } }) =>
    mobileTopBarHeight}px);
  `}

  ${media.smallerThanMinTablet`
    min-height: calc(100vh - ${({ theme: { mobileMenuHeight } }) =>
      mobileMenuHeight}px - ${({ theme: { mobileTopBarHeight } }) =>
    mobileTopBarHeight}px);
  `}
`;

const Loading = styled.div`
  flex: 1 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
`;

const ContentWrapper = styled.div`
  width: 100%;
`;

interface Props {
  project: IProjectData | Error | null | undefined;
}

const ProjectsShowPage = memo<Props>(({ project }) => {
  const projectId = !isNilOrError(project) ? project.id : undefined;
  const projectNotFound = isError(project);
  const processType = !isNilOrError(project)
    ? project.attributes.process_type
    : undefined;

  const locale = useLocale();
  const tenant = useAppConfiguration();
  const phases = usePhases(projectId);
  const events = useEvents(projectId);
  const user = useAuthUser();

  const loading = useMemo(() => {
    return (
      isUndefined(locale) ||
      isUndefined(tenant) ||
      isUndefined(project) ||
      isUndefined(phases) ||
      isUndefined(events)
    );
  }, [locale, tenant, project, phases, events]);

  const isUnauthorized = useMemo(() => {
    if (!isApiError(project)) return false;

    return project.json.errors.base[0].error === 'Unauthorized!';
  }, [project]);

  const userSignedInButUnauthorized = !isNilOrError(user) && isUnauthorized;
  const userNotSignedInAndUnauthorized = isNilOrError(user) && isUnauthorized;

  let content: JSX.Element | null = null;

  if (userNotSignedInAndUnauthorized) return <ForbiddenRoute />;

  if (userSignedInButUnauthorized) {
    content = <ProjectNotVisible />;
  } else if (loading) {
    content = (
      <Loading>
        <Spinner />
      </Loading>
    );
  } else if (projectNotFound) {
    content = <ProjectNotFound />;
  } else if (projectId && processType) {
    content = (
      <ContentWrapper id="e2e-project-page">
        <ProjectHeader projectId={projectId} />
        {processType === 'continuous' ? (
          <>
            <ContinuousIdeas projectId={projectId} />
            <ContinuousSurvey projectId={projectId} />
            <ContinuousPoll projectId={projectId} />
            <ContinuousVolunteering projectId={projectId} />
          </>
        ) : (
          <TimelineContainer projectId={projectId} />
        )}
        <ProjectEvents projectId={projectId} />
      </ContentWrapper>
    );
  }

  const bgColor =
    !isNilOrError(events) && events.length > 0 ? '#fff' : colors.background;

  return (
    <Container background={bgColor}>
      {!isNilOrError(project) && <ProjectHelmet project={project} />}
      {content}
    </Container>
  );
});

const ProjectsShowPageWrapper = memo<WithRouterProps>(
  ({ location: { pathname }, params: { slug } }) => {
    const project = useProject({ projectSlug: slug });

    const urlSegments = pathname
      .replace(/^\/|\/$/g, '')
      .split('/')
      .filter((segment) => segment !== '');

    if (urlSegments.length > 3 && urlSegments[1] === 'projects') {
      // redirect old childRoutes (e.g. /info, /process, ...) to the project index location
      clHistory.replace(`/${urlSegments.slice(1, 3).join('/')}`);
    } else if (slug) {
      return <ProjectsShowPage project={project} />;
    }

    return null;
  }
);

const ProjectsShowPageWrapperWithHoC = withRouter(ProjectsShowPageWrapper);

export default ProjectsShowPageWrapperWithHoC;
